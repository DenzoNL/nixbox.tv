{ ... }:

{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "google_translate"
      "hue"
      "met"
    ];
    extraPackages = python3Packages: with python3Packages; [
      getmac
      psycopg2 # provide package for postgresql support
      pyatv # Apple TV
      pychromecast
      python-otbr-api
      spotipy
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