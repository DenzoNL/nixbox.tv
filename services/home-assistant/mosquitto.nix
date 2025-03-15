{ config, ... }:

{
  sops.secrets."mosquitto/hass_password" = {};

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users.hass = {
          acl = [
            "readwrite #"
          ];
          hashedPasswordFile = config.sops.secrets."mosquitto/hass_password".path;
        };
      }
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [ 1883 ]; # open port for ffxiv
  };
}