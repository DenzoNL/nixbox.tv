{ pkgs, ... }:

{
  services.code-server = {
    enable = true;
    auth = "none"; # Protected by Tailscale
    disableTelemetry = true;
    disableUpdateCheck = true;
    proxyDomain = "code.nixbox.tv";
    user = "denzo";
  };

  services.nginx.virtualHosts."code.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    useACMEHost = "nixbox.tv";

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:4444/";
      proxyWebsockets = true;
    };

    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection upgrade;
      proxy_set_header Accept-Encoding gzip;
    '';
  };
}