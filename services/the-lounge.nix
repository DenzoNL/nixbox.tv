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
    # Enable Let's Encrypt
    forceSSL = true;
    useACMEHost = "nixbox.tv";

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:9000/";
      proxyWebsockets = true;
    };
  };
}