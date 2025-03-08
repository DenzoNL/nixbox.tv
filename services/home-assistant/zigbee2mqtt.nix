{ config, ... }:

{
  sops.secrets."zigbee2mqtt/secret.yaml" = {
    owner = config.users.users.zigbee2mqtt.name;
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      homeassistant = config.services.home-assistant.enable;
      permit_join = true;
      mqtt = {
        user = "hass";
        password = "!${config.sops.secrets."zigbee2mqtt/secret.yaml".path} password";
      };
      serial = {
        port = "/dev/ttyUSB0";
        adapter = "zstack";
      };
      frontend = {
        enabled = true;
        port = 8083;
      };
    };
  };

  services.nginx.virtualHosts."zigbee2mqtt.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:8083";
      proxyWebsockets = true;
    };
  };
}