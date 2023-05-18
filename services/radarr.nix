{ ... }:

{
  services.radarr = {
    enable = true;
    openFirewall = true;
  };

  services.nginx.virtualHosts."radarr.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    enableACME = true;

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:7878/";
    };
  };
}