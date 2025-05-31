{ config, domain, ... }:

{
  services.immich-public-proxy = {
    enable = true;
    port = 3069;
    immichUrl = "http://100.69.0.42:2283";
  };

  services.nginx.virtualHosts."public.immich.${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.immich-public-proxy.port}";
      proxyWebsockets = true;
    };
  };
}