{ config, domain, ... }:

{
  services.audiobookshelf = {
    enable = true;
  };

  services.nginx.virtualHosts."audiobookshelf.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.audiobookshelf.port}/";
      proxyWebsockets = true;
    };
    extraConfig = ''
      # Allow large file uploads
      client_max_body_size 10240M;
    '';
  };
}