{ ... }:

{
  services.tautulli = {
    enable = true;
    port = 8282;
  };

  services.nginx.virtualHosts."tautulli.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:8282/";
      proxyWebsockets = true;
    };
  };
}