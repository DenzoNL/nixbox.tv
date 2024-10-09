{ config, ... }:

{
  sops.secrets."miniflux/adminCredentials" = {};

  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets."miniflux/adminCredentials".path;
    config = {
      BASE_URL = "https://rss.nixbox.tv/";
      PORT = "9999";
    };
  };

  services.nginx.virtualHosts."rss.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:9999/";
      proxyWebsockets = true;
    };
  };
}