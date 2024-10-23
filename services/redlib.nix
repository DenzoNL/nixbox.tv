{ config, ... }:

{
  services.redlib = {
    enable = true;
    port = 8069;
  };

  services.nginx.virtualHosts."reddit.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.redlib.port}/";
      proxyWebsockets = true;
    };
  };

}