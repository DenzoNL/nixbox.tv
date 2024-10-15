{ ...}:

{
  services.immich = {
    enable = true;
  };

  services.nginx.virtualHosts."immich.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:3001/";
      proxyWebsockets = true;
    };
  };
}