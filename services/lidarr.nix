{ ... }:

{
  services.lidarr = {
    enable = true;
  };

  services.nginx.virtualHosts."lidarr.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:8686/";
      proxyWebsockets = true;
    };
  };
}