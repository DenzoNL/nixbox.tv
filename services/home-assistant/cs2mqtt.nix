{ config, customPkgs, domain, ... }:

{
  users.users.cs2mqtt = {
    isSystemUser = true;
    group = "cs2mqtt";
    home = "/var/lib/cs2mqtt";
    createHome = true;
  };

  users.groups.cs2mqtt = { };

  sops.secrets."cs2mqtt" = {
    owner = config.users.users.cs2mqtt.name;
  };

  systemd.services.cs2mqtt = {
    description = "CS2MQTT Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${customPkgs.cs2mqtt}/bin/LupusBytes.CS2.GameStateIntegration.Api";
      Restart = "always";
      User = "cs2mqtt";
      Group = "cs2mqtt";
      WorkingDirectory = "/var/lib/cs2mqtt";
      EnvironmentFile = config.sops.secrets."cs2mqtt".path;
    };
  };

  services.nginx.virtualHosts."cs2mqtt.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:5000";
      proxyWebsockets = true;
    };
  };
}
