{ ... }:

{
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  services.nginx.virtualHosts."sonarr.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    enableACME = true;
    acmeRoot = null; # Force DNS-01 validation
    
    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:8989/";
    };
  };
}