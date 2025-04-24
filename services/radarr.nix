{ domain, ... }:

{
  services.radarr = {
    enable = true;
  };

  services.nginx.virtualHosts."radarr.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:7878/";
      proxyWebsockets = true;
    };
  };
}