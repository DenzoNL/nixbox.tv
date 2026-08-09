{ domain, ... }:

{
  # LAN clients reach the web UIs directly: OPNsense/Unbound split-horizon DNS
  # resolves *.nixbox.tv to the local IP, so 80/443 must be open beyond the
  # tailscale0 trusted interface. WAN is still NAT'd behind OPNsense.
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # This box federates with large rooms (Matrix HQ etc.), which periodically
  # storm it with concurrent /_matrix/federation state-resolution requests. The
  # stock 512 worker_connections gets exhausted ("512 worker_connections are
  # not enough while connecting to upstream"), and once the pool is full nginx
  # can't service anything else — including our own browser clients, whose
  # sync/account_data/media requests then abort with NetworkError (breaking,
  # e.g., Element's secure-backup setup). Give nginx a much larger connection
  # pool, and the file descriptors to back it (each proxied connection = two).
  systemd.services.nginx.serviceConfig.LimitNOFILE = 65536;

  services.nginx = {
    enable = true;

    # Use recommended settings (including the cipher suites; an AES256-only
    # override used to live here but only weakened them)
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    eventsConfig = "worker_connections 8192;";
    appendConfig = "worker_rlimit_nofile 32768;";

    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;
    '';
  };

  # Helper for the common vhost: terminate TLS with the wildcard cert and proxy
  # to a localhost port. Services use it as:
  #   services.nginx.virtualHosts."x.${domain}" = mkProxy 1234;
  # and merge extra vhost settings with `// { ... }` when needed.
  _module.args.mkProxy = port: {
    forceSSL = true;
    useACMEHost = domain;
    kTLS = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}/";
      proxyWebsockets = true;
    };
  };
}
