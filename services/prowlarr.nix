{ ... }:

{
  services.prowlarr = {
    enable = true;
  };

  services.nginx.virtualHosts."prowlarr.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:9696/";
      proxyWebsockets = true;
    };
  };
}