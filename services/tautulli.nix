{ domain, ... }:

{
  services.tautulli = {
    enable = true;
    port = 8282;
  };

  services.nginx.virtualHosts."tautulli.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:8282/";
      proxyWebsockets = true;
    };
  };
}