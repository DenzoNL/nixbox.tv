{ config, domain, pkgs, ... }:

{
  sops.secrets."zigbee2mqtt/secret.yaml" = {
    owner = config.users.users.zigbee2mqtt.name;
  };

  services.zigbee2mqtt = {
    enable = true;
    package = pkgs.zigbee2mqtt_2;
    settings = {
      advanced = {
        homeassistant_legacy_entity_attributes = false;
        homeassistant_legacy_triggers = false;
        legacy_api = false;
        legacy_availability_payload = false;
      };
      device_option = {
        legacy = false;
      };
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

  services.nginx.virtualHosts."z2m.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:8083";
      proxyWebsockets = true;
    };
  };
}