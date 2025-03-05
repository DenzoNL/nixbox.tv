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

  services.nginx.virtualHosts."home.nixbox.tv" = {
    extraConfig = ''
      proxy_buffering off;
    '';
    locations."/" = {
      proxyPass = "http://localhost:8123";
      proxyWebsockets = true;
    };
  };
}