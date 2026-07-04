{
  config,
  domain,
  mkProxy,
  ...
}:

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
      PAPERLESS_PROXY_SSL_HEADER = [
        "HTTP_X_FORWARDED_PROTO"
        "https"
      ];
      PAPERLESS_URL = "https://${hostName}";
      PAPERLESS_USE_X_FORWARD_HOST = true;
      PAPERLESS_USE_X_FORWARD_PORT = true;
    };
  };

  services.nginx.virtualHosts.${hostName} = mkProxy port // {
    extraConfig = ''
      client_max_body_size 25M;
    '';
  };
}
