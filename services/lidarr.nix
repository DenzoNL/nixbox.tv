{ ... }:

{
  services.lidarr = {
    enable = true;
    openFirewall = true;
  };

  services.nginx.virtualHosts."lidarr.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    enableACME = true;

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:8686/";
    };
  };
}