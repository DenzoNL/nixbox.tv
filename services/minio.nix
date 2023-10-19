{ config,... }:

{
  services.minio = {
    enable = true;
    listenAddress = "127.0.0.1:9000";
    consoleAddress = "127.0.0.1:9123"; # Prevent conflict with Prometheus
    rootCredentialsFile = config.sops.secrets."minio/rootCredentials".path;
  };

  sops.secrets = {
    "minio/rootCredentials" = {
      owner = config.users.users.minio.name;
    };
  };

  services.nginx.virtualHosts."minio.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    enableACME = true;

    extraConfig = ''
      ignore_invalid_headers off;
      client_max_body_size 0;
      proxy_buffering off;
      proxy_request_buffering off;
    '';

    locations."/" = {
      proxyPass = "http://127.0.0.1:9123/";
      extraConfig = ''
        # This is necessary to pass the correct IP to be hashed
        real_ip_header X-Real-IP;

        proxy_connect_timeout 300;

        # To support websocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        chunked_transfer_encoding off;
      '';
    };
  };

  services.nginx.virtualHosts."s3.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    enableACME = true;

    extraConfig = ''
      ignore_invalid_headers off;
      client_max_body_size 0;
      proxy_buffering off;
      proxy_request_buffering off;
    '';

    locations."/" = {
      proxyPass = "http://127.0.0.1:9000/";
      extraConfig = ''
        proxy_connect_timeout 300;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
    '';
    };
  };
}