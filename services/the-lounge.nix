{ ... }:

{
  services.thelounge = {
    enable = true;
    extraConfig = {
      reverseProxy = true;
      prefetch = true;
    };
  };

  services.nginx.virtualHosts."irc.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:9000/";
      proxyWebsockets = true;
    };
  };
}