{ domain, ... }:

{
  services.nginx.virtualHosts."public.immich.${domain}" = {
    locations."/" = {
      proxyPass = "http://nixbox:3069";
      proxyWebsockets = true;
    };
  };
}