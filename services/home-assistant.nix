{ config, ... }:

{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "apple_tv"
      "cast"
      "google_translate"
      "homekit"
      "http"
      "hue"
      "met"
      "mqtt"
      "otbr"
      "plex"
      "sonarr"
      "spotify"
      "steam_online"
      "upnp"
      "withings"
    ];
    extraPackages = python3Packages: with python3Packages; [
      aiohomekit
      isal
      psycopg2 # provide package for postgresql support
      zlib-ng
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};
      # Allow access by reverse proxy
      http = {
        server_host = "::1";
        trusted_proxies = [ "::1" ];
        use_x_forwarded_for = true;
      };
      # Connect to PostgreSQL
      recorder.db_url = "postgresql://@/hass";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensureDBOwnership = true;
    }];
  };

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

  services.nginx.virtualHosts."home.nixbox.tv" = {
    extraConfig = ''
      proxy_buffering off;
    '';
    locations."/" = {
      proxyPass = "http://localhost:8123";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."zigbee2mqtt.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:8083";
      proxyWebsockets = true;
    };
  };
}