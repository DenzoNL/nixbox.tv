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
    locations."/" = {
      proxyPass = "http://localhost:8069/";
      proxyWebsockets = true;
    };
  };

}