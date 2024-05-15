{ ... }:

{
  services.bazarr = {
    enable = true;
  };

  services.nginx.virtualHosts."bazarr.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    useACMEHost = "nixbox.tv";

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:6767/";
      proxyWebsockets = true;
    };

    extraConfig = ''
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $http_connection;
    '';
  };
}