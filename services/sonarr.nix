{ domain, ... }:

{
  services.sonarr = {
    enable = true;
  };

  services.nginx.virtualHosts."sonarr.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:8989/";
      proxyWebsockets = true;
    };
  };
}