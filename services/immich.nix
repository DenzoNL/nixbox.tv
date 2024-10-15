{ ...}:

{
  services.immich = {
    enable = true;
  };

  services.nginx.virtualHosts."immich.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:3001/";
      proxyWebsockets = true;
    };
    extraConfig = ''
      # Allow large file uploads
      client_max_body_size 50000M;

      # Configure timeout
      proxy_read_timeout 600s;
      proxy_send_timeout 600s;
      send_timeout       600s;
    '';
  };
}