{ ... }:

{
  services.samba-wsdd.enable = true; # Make shares visible for Windows 10 clients
  networking.firewall.allowedTCPPorts = [ 5357 ]; # wsdd
  networking.firewall.allowedUDPPorts = [ 3702 ]; # wsdd

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nixbox";
        "netbios name" = "nixbox";
        "security" = "user";
        # LAN + Tailscale (CGNAT range) + loopback
        "hosts allow" = "192.168.0.0/24 100.64.0.0/10 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      storage = {
        path = "/mnt/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "0755";
        "force user" = "denzo";
        "force group" = "mediausers";
      };
    };
  };
}
