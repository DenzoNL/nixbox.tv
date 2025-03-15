{  config, pkgs, ... }:

{
  sops.secrets.homeassistant = {
    owner = config.users.users.hass.name;
    path = "${config.services.home-assistant.configDir}/secrets.yaml";
  };

  /** Required open ports for HomeKit bridge */
  networking.firewall = {
    allowedUDPPorts = [ 5353 ];   # mDNS
    allowedTCPPorts = [ 21064 ];  # bridge
  };

  services.home-assistant = {
    enable = true;
    customComponents = with pkgs.home-assistant-custom-components; [
      spook
    ];
    extraComponents = [
      "apple_tv"
      "cast"
      "google_translate"
      "homekit"
      "homewizard"
      "http"
      "lidarr"
      "met"
      "mqtt"
      "otbr"
      "plex"
      "prometheus"
      "radarr"
      "rtorrent"
      "sonarr"
      "spotify"
      "steam_online"
      "tailscale"
      "tautulli"
      "unifi"
      "upnp"
      "webostv"
      "whisper"
      "withings"
      "wyoming"
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
      homeassistant = {
        media_dirs = {
          media = "/mnt/storage";
        };
      };
      # Allow access by reverse proxy
      http = {
        server_host = "::1";
        trusted_proxies = [ "::1" ];
        use_x_forwarded_for = true;
      };
      mqtt.binary_sensor = [
        { 
          name = "FFXIV | Steven Seagal | Online";
          state_topic = "ffxiv/StevenSeagal/Event/Login";
          value_template = "{{ value_json.LoggedIn }}";
          icon = "mdi:account-badge";
          payload_on = true;
          payload_off = false;
          device_class = "connectivity";
        }
        { 
          name = "FFXIV | Ophelia Moore | Online";
          state_topic = "ffxiv/OpheliaMoore/Event/Login";
          value_template = "{{ value_json.LoggedIn }}";
          icon = "mdi:account-badge";
          payload_on = true;
          payload_off = false;
          device_class = "connectivity";
        }
        { 
          name = "FFXIV | Steven Seagal | In Combat";
          state_topic = "ffxiv/StevenSeagal/Player/Conditions/InCombat";
          value_template = "{{ value_json.Active }}";
          icon = "mdi:sword-cross";
          payload_on = true;
          payload_off = false;
          device_class = "safety";
        }
        { 
          name = "FFXIV | Ophelia Moore | In Combat";
          state_topic = "ffxiv/OpheliaMoore/Player/Conditions/InCombat";
          value_template = "{{ value_json.Active }}";
          icon = "mdi:sword-cross";
          payload_on = true;
          payload_off = false;
          device_class = "safety";
        }
      ];
      mqtt.sensor = [
        { 
          name = "FFXIV | Steven Seagal | Character";
          state_topic = "ffxiv/StevenSeagal/Event/Login";
          value_template = "{{ value_json.Character }}";
          icon = "mdi:account-badge";
        }
        { 
          name = "FFXIV | Steven Seagal | HP";
          state_topic = "ffxiv/StevenSeagal/Player/Combat/Stats";
          value_template = "{{ value_json.HP }}";
          unit_of_measurement = "HP";
          icon = "mdi:heart";
        }
        { 
          name = "FFXIV | Steven Seagal | MP";
          state_topic = "ffxiv/StevenSeagal/Player/Combat/Stats";
          value_template = "{{ value_json.MP }}";
          unit_of_measurement = "MP";
          icon = "mdi:water";
        }
        { 
          name = "FFXIV | Steven Seagal | Current Zone";
          state_topic = "ffxiv/StevenSeagal/Event/TerritoryChanged";
          value_template = "{{ value_json.Name }} ({{ value_json.Region }})";
          icon = "mdi:map-marker";
        }
        { 
          name = "FFXIV | Ophelia Moore | Character";
          state_topic = "ffxiv/OpheliaMoore/Event/Login";
          value_template = "{{ value_json.Character }}";
          icon = "mdi:account-badge";
        }
        { 
          name = "FFXIV | Ophelia Moore | HP";
          state_topic = "ffxiv/OpheliaMoore/Player/Combat/Stats";
          value_template = "{{ value_json.HP }}";
          unit_of_measurement = "HP";
          icon = "mdi:heart";
        }
        { 
          name = "FFXIV | Ophelia Moore | MP";
          state_topic = "ffxiv/OpheliaMoore/Player/Combat/Stats";
          value_template = "{{ value_json.MP }}";
          unit_of_measurement = "MP";
          icon = "mdi:water";
        }
        { 
          name = "FFXIV | Ophelia Moore | Current Zone";
          state_topic = "ffxiv/OpheliaMoore/Event/TerritoryChanged";
          value_template = "{{ value_json.Name }} ({{ value_json.Region }})";
          icon = "mdi:map-marker";
        }
      ];
      # Connect to PostgreSQL
      recorder.db_url = "postgresql://@/hass";
      # Include UI defined automations
      "automation ui" = "!include automations.yaml";
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
}