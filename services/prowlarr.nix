{ ... }:

{
  services.prowlarr = {
    enable = true;
  };

  services.nginx.virtualHosts."prowlarr.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    useACMEHost = "nixbox.tv";

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:9696/";
      proxyWebsockets = true;
    };
  };
}