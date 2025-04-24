{ domain, ... }:

{
  services.prowlarr = {
    enable = true;
  };

  services.nginx.virtualHosts."prowlarr.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:9696/";
      proxyWebsockets = true;
    };
  };
}