{ ... }:

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

  services.wyoming.faster-whisper.servers."home-assistant" = {
    enable = true;
    language = "nl";
    model = "small-int8";
    uri = "tcp://0.0.0.0:10300";
  };

  services.wyoming.piper.servers."home-assistant" = {
    enable = true;
    voice = "nl_BE-rdh-medium";
    uri = "tcp://0.0.0.0:10200";
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