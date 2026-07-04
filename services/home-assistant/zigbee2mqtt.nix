{
  config,
  domain,
  mkProxy,
  pkgs,
  ...
}:

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
      homeassistant.enabled = config.services.home-assistant.enable;
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
        # Bind to IPv4 loopback to match the nginx proxy target (mkProxy).
        host = "127.0.0.1";
      };
    };
  };

  # z2m exits immediately when the broker is unreachable, so make sure
  # mosquitto is up first (it raced mosquitto at boot and crash-looped once
  # or twice before recovering).
  systemd.services.zigbee2mqtt = {
    after = [ "mosquitto.service" ];
    wants = [ "mosquitto.service" ];
  };

  services.nginx.virtualHosts."z2m.${domain}" = mkProxy 8083;
}
