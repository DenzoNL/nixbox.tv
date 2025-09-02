{ config, domain, ... }:

let
  hostName = "webdav.${domain}";
  port = 6065;
  dataDir = "/var/lib/webdav";
in
{
  # Declare the webdav secret with correct ownership
  sops.secrets.webdav = {
    owner = "webdav";
  };

  # WebDAV service configuration
  services.webdav = {
    enable = true;
    settings = {
      address = "127.0.0.1";
      port = port;
      directory = dataDir;
      permissions = "CRUD";  # Create, Read, Update, Delete permissions
      users = [
        {
          username = "{env}ENV_USERNAME";
          password = "{env}ENV_PASSWORD";
          permissions = "CRUD";
        }
      ];
    };
    environmentFile = config.sops.secrets.webdav.path;
  };

  # Ensure data directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 webdav webdav -"
  ];

  # Nginx reverse proxy configuration
  services.nginx.virtualHosts.${hostName} = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}/";
      extraConfig = ''
        # WebDAV specific settings not covered by recommendedProxySettings
        proxy_request_buffering off;
        client_max_body_size 0;
        
        # WebDAV method headers
        proxy_set_header Depth $http_depth;
        proxy_set_header Destination $http_destination;
        proxy_set_header Overwrite $http_overwrite;
        proxy_set_header Translate $http_translate;
      '';
    };
  };

  # Open firewall for internal access
  networking.firewall.allowedTCPPorts = [ port ];
}