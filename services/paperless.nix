{ config, domain, ... }:

let
  hostName = "paperless.${domain}";
  port = config.services.paperless.port;
in
{
  services.paperless = {
    enable = true;
    database = {
      createLocally = true;
    };
    settings = {
      PAPERLESS_PROXY_SSL_HEADER = ["HTTP_X_FORWARDED_PROTO" "https"];
      PAPERLESS_URL = "https://${hostName}";
      USE_X_FORWARD_HOST = true;
      USE_X_FORWARD_PORT = true;
    };
  };

  services.nginx.virtualHosts.${hostName} = {
    locations."/" = {
      proxyPass = "http://localhost:${toString port}/";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 25M;
      '';
    };
  };
}