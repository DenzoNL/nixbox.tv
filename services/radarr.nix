{ ... }:

{
  services.radarr = {
    enable = true;
  };

  services.nginx.virtualHosts."radarr.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:7878/";
      proxyWebsockets = true;
    };
  };
}