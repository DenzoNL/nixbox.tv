{ config, lib, ... }:

{
  services.rtorrent = {
    enable = true;
    downloadDir = "/mnt/storage/downloads";
    openFirewall = true;
    configText = let cfg = config.services.rtorrent;
    in lib.mkForce ''
      ## Instance layout (base paths)
      method.insert = cfg.basedir,  private|const|string, (cat,"${cfg.dataDir}/")
      method.insert = cfg.download, private|const|string, (cat,"${cfg.downloadDir}")
      method.insert = cfg.logs,     private|const|string, (cat,(cfg.basedir),"log/")
      method.insert = cfg.logfile,  private|const|string, (cat,(cfg.logs),"rtorrent-",(system.time),".log")
      method.insert = cfg.session,  private|const|string, (cat,(cfg.basedir),"session/")
      method.insert = cfg.watch,    private|const|string, (cat,(cfg.basedir),"watch/")

      # Flood support
      method.redirect=load.throw,load.normal
      method.redirect=load.start_throw,load.start
      method.insert=d.down.sequential,value|const,0
      method.insert=d.down.sequential.set,value|const,0

      # RPC Socket
      method.insert = cfg.rpcsock, private|const|string, (cat,"${cfg.rpcSocket}")

      ## Create instance directories
      execute.throw = sh, -c, (cat,\
          "mkdir -p \"",(cfg.download),"\" ",\
          "\"",(cfg.logs),"\" ",\
          "\"",(cfg.session),"\" ",\
          "\"",(cfg.watch),"/load\" ",\
          "\"",(cfg.watch),"/start\" ")

      ## Listening port for incoming peer traffic (fixed; you can also randomize it)
      network.port_range.set = ${toString cfg.port}-${toString cfg.port}
      network.port_random.set = no

      ## Tracker-less torrent and UDP tracker support
      ## (conservative settings for 'private' trackers, change for 'public')
      dht.mode.set = disable
      protocol.pex.set = no

      trackers.use_udp.set = no

      ## Peer settings
      throttle.max_uploads.set = 100
      throttle.max_uploads.global.set = 250

      throttle.min_peers.normal.set = 20
      throttle.max_peers.normal.set = 60
      throttle.min_peers.seed.set = 30
      throttle.max_peers.seed.set = 80
      trackers.numwant.set = 80

      protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

      ## Limits for file handle resources, this is optimized for
      ## an `ulimit` of 1024 (a common default). You MUST leave
      ## a ceiling of handles reserved for rTorrent's internal needs!
      network.http.max_open.set = 50
      network.max_open_files.set = 600
      network.max_open_sockets.set = 300

      ## Memory resource usage (increase if you have a large number of items loaded,
      ## and/or the available resources to spend)
      pieces.memory.max.set = 1800M
      network.xmlrpc.size_limit.set = 32M

      ## Basic operational settings (no need to change these)
      session.path.set = (cat, (cfg.session))
      directory.default.set = (cat, (cfg.download))
      log.execute = (cat, (cfg.logs), "execute.log")
      #log.xmlrpc = (cat, (cfg.logs), "xmlrpc.log")
      execute.nothrow = sh, -c, (cat, "echo >",\
          (session.path), "rtorrent.pid", " ",(system.pid))


      ## Other operational settings (check & adapt)
      encoding.add = UTF-8
      system.umask.set = 0002
      system.cwd.set = (directory.default)
      network.http.dns_cache_timeout.set = 25
      schedule2 = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))
      #pieces.hash.on_completion.set = no
      #view.sort_current = seeding, greater=d.ratio=
      #keys.layout.set = qwerty
      #network.http.capath.set = "/etc/ssl/certs"
      #network.http.ssl_verify_peer.set = 0
      #network.http.ssl_verify_host.set = 0

      ## Some additional values and commands
      method.insert = system.startup_time, value|const, (system.time)
      method.insert = d.data_path, simple,\
          "if=(d.is_multi_file),\
              (cat, (d.directory), /),\
              (cat, (d.directory), /, (d.name))"
      method.insert = d.session_file, simple, "cat=(session.path), (d.hash), .torrent"

      ## Watch directories (add more as you like, but use unique schedule names)
      ## Add torrent
      schedule2 = watch_load, 11, 10, ((load.verbose, (cat, (cfg.watch), "load/*.torrent")))
      ## Add & download straight away
      schedule2 = watch_start, 10, 10, ((load.start_verbose, (cat, (cfg.watch), "start/*.torrent")))

      ## Run the rTorrent process as a daemon in the background
      ## (and control via XMLRPC sockets)
      system.daemon.set = true
      network.scgi.open_local = (cat,(cfg.rpcsock))
      schedule = scgi_group,0,0,"execute.nothrow=chown,\":rtorrent\",(cfg.rpcsock)"
      schedule = scgi_permission,0,0,"execute.nothrow=chmod,\"g+w,o=\",(cfg.rpcsock)"
      #execute.nothrow = chmod,770,(cat,(session.path),rpc.socket)

      ## Logging:
      ##   Levels = critical error warn notice info debug
      ##   Groups = connection_* dht_* peer_* rpc_* storage_* thread_* tracker_* torrent_*
      print = (cat, "Logging to ", (cfg.logfile))
      log.open_file = "log", (cfg.logfile)
      log.add_output = "info", "log"
      #log.add_output = "tracker_debug", "log"

      ### END of rtorrent.rc ###
    '';
  };
}
