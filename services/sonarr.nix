{ ... }:

{
  services.sonarr = {
    enable = true;
  };

  services.nginx.virtualHosts."sonarr.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    useACMEHost = "nixbox.tv";

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:8989/";
    };
  };
}