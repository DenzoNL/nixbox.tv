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
      "discord"
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