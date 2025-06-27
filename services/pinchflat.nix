{ config, domain, lib, ... }:

{
  services.pinchflat = {
    enable = true;
    selfhosted = true;
    mediaDir = "/mnt/storage/youtube";
  };

  users.groups.mediausers = {
    members = [ config.services.pinchflat.user ];
  };

  services.nginx.virtualHosts."pinchflat.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.pinchflat.port}/";
      proxyWebsockets = true;
    };
  };
}