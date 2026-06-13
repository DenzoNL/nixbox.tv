{
  config,
  domain,
  mkProxy,
  ...
}:

{
  services.immich = {
    enable = true;
    # Bind to IPv4 loopback so it matches the nginx proxy target (mkProxy uses
    # 127.0.0.1); the default "localhost" can resolve to ::1 and cause a 502.
    host = "127.0.0.1";
  };

  services.nginx.virtualHosts."immich.${domain}" = mkProxy config.services.immich.port // {
    extraConfig = ''
      # Allow large file uploads
      client_max_body_size 50000M;

      # Configure timeout
      proxy_read_timeout 600s;
      proxy_send_timeout 600s;
      send_timeout       600s;
    '';
  };
}
