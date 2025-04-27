{ domain, ... }:

{
  services.tautulli = {
    enable = true;
    port = 8282;
  };

  services.nginx.virtualHosts."tautulli.${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:8282/";
      proxyWebsockets = true;
    };
  };
}