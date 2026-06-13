{
  config,
  domain,
  lib,
  mkProxy,
  ...
}:

{
  services.flood = {
    enable = true;
    # Bind to IPv4 loopback to match the nginx proxy target (mkProxy uses
    # 127.0.0.1); the default "localhost" can resolve to ::1 and cause a 502.
    host = "127.0.0.1";
    extraArgs = [
      "--allowedpath=/mnt/storage/downloads"
      "--rtsocket=${config.services.rtorrent.rpcSocket}"
    ];
  };

  systemd.services.flood = {
    serviceConfig = {
      # Grant Flood access to the rtorrent RPC socket
      SupplementaryGroups = [ "rtorrent" ];
      # Grant Flood RW access to the download directory
      ReadWritePaths = [ "/mnt/storage/downloads" ];
    };
  };

  # Flood's activity-stream lives under /api and is server-sent events; disable
  # buffering/caching on that location so live updates aren't held back by nginx
  # (per Flood's nginx wiki). recursiveUpdate keeps mkProxy's "/" location.
  services.nginx.virtualHosts."flood.${domain}" = lib.recursiveUpdate (mkProxy 3000) {
    locations."/api" = {
      proxyPass = "http://127.0.0.1:3000";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
        proxy_cache off;
      '';
    };
  };
}
