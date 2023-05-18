{ ... }:

{
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  services.nginx.virtualHosts."sonarr.nixbox.tv" = {
    # Enable Let's Encrypt
    addSSL = true;
    enableACME = true;

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:8989/";
    };
  };
}