{ domain, ... }:

{
  services.thelounge = {
    enable = true;
    extraConfig = {
      reverseProxy = true;
      prefetch = true;
    };
  };

  services.nginx.virtualHosts."irc.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:9000/";
      proxyWebsockets = true;
    };
  };
}