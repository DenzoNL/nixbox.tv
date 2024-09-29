{ ... }:

{
  services.samba-wsdd.enable = true; # Make shares visible for Windows 10 clients
  networking.firewall.allowedTCPPorts = [5357]; # wsdd
  networking.firewall.allowedUDPPorts = [3702]; # wsdd

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nixbox";
        "netbios name" = "nixbox";
        "security" = "user";
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "all";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      storage = {
        path = "/mnt/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "denzo";
        "force group" = "mediausers";
      };
    };
  };
}