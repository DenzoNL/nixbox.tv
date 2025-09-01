{ domain, pkgs, ... }:

let
  hostName = "memos.${domain}";
  port = 5230;
  dataDir = "/var/lib/memos";
  user = "memos";
  group = "memos";
in
{
  # Create memos user and group
  users.groups.${group} = {};
  users.users.${user} = {
    isSystemUser = true;
    inherit group;
    home = dataDir;
    createHome = true;
    extraGroups = [ "mediausers" ];
  };

  # PostgreSQL database configuration
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "memos" ];
    ensureUsers = [{
      name = user;
      ensureDBOwnership = true;
    }];
  };

  # Create systemd service for memos
  systemd.services.memos = {
    description = "Memos - A privacy-first, lightweight note-taking service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "postgresql.service" ];
    requires = [ "postgresql.service" ];

    environment = {
      MEMOS_MODE = "prod";
      MEMOS_PORT = toString port;
      MEMOS_DRIVER = "postgres";
      MEMOS_DSN = "postgresql:///${user}?host=/run/postgresql";
      MEMOS_DATA = dataDir;
    };

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      ExecStart = "${pkgs.memos}/bin/memos";
      Restart = "on-failure";
      RestartSec = "5s";
      
      # Security hardening
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      ReadWritePaths = [ dataDir ];
      StateDirectory = "memos";
      StateDirectoryMode = "0700";
    };

    preStart = ''
      # Ensure data directory exists with correct permissions
      mkdir -p ${dataDir}
      chown -R ${user}:${group} ${dataDir}
      chmod 700 ${dataDir}
      
      # Note: If database issues persist, you may need to drop and recreate the database:
      # sudo -u postgres psql -c "DROP DATABASE IF EXISTS memos;"
      # sudo -u postgres psql -c "CREATE DATABASE memos OWNER memos;"
    '';
  };

  # Nginx reverse proxy configuration
  services.nginx.virtualHosts.${hostName} = {
    locations."/" = {
      proxyPass = "http://localhost:${toString port}/";
      proxyWebsockets = true;
    };
  };

  # Open firewall for internal access
  networking.firewall.allowedTCPPorts = [ port ];
}