{ ... }:

{
  services.sonarr = {
    enable = true;
  };

  services.nginx.virtualHosts."sonarr.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:8989/";
    };
  };
}