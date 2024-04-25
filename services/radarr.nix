{ ... }:

{
  services.radarr = {
    enable = true;
  };

  services.nginx.virtualHosts."radarr.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    enableACME = true;
    acmeRoot = null; # Force DNS-01 validation

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:7878/";
    };

    extraConfig = ''
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $http_connection;
    '';
  };
}