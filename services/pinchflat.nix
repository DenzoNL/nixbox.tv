{ config, domain, lib, ... }:

{
  services.pinchflat = {
    enable = true;
    selfhosted = true;
    mediaDir = "/mnt/storage/youtube";
  };

  users.users.pinchflat = {
    isSystemUser = true;
    group = "pinchflat";
  };

  users.groups.pinchflat = {};

  users.groups.mediausers = {
    members = [ "pinchflat" ];
  };

  systemd.services.pinchflat.serviceConfig.User = "pinchflat";
  systemd.services.pinchflat.serviceConfig.DynamicUser = lib.mkForce false;

  services.nginx.virtualHosts."pinchflat.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.pinchflat.port}/";
      proxyWebsockets = true;
    };
  };
}