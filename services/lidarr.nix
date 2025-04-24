{ domain, ... }:

{
  services.lidarr = {
    enable = true;
  };

  services.nginx.virtualHosts."lidarr.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:8686/";
      proxyWebsockets = true;
    };
  };
}