{ pkgs, ... }:

{
  users.users.redlib = {
    group = "redlib";
    shell = pkgs.bashInteractive;
    home = "/var/lib/redlib";
    description = "redlib daemon user";
    isSystemUser = true;
  };

  users.groups.redlib = {};

  systemd.services.redlib = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    before = [ "nginx.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.redlib}/bin/redlib -a 0.0.0.0 -p 8069";
      User = "redlib";
      Group = "redlib";
      Type = "simple";
      Restart = "on-failure";
      WorkingDirectory = "/var/lib/redlib";
    };
  };

  systemd.tmpfiles.rules = [ "d '/var/lib/redlib' 0755 redlib redlib -" ];

  services.nginx.virtualHosts."reddit.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    useACMEHost = "nixbox.tv";
    
    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:8069/";
    };

    extraConfig = ''
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $http_connection;
    '';
  };

}