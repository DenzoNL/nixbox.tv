{ config, domain, ... }:

{
  services.immich = {
    enable = true;
    settings.server.externalDomain = "https://public.immich.${domain}";
  };

  services.immich-public-proxy = {
    enable = true;
    port = 3069;
    immichUrl = "http://localhost:${toString config.services.immich.port}";
  };

  services.nginx.virtualHosts."immich.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.immich.port}/";
      proxyWebsockets = true;
    };
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