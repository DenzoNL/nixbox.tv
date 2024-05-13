{ pkgs, ... }:

{
  users.users.flood = {
    group = "flood";
    extraGroups = [ "rtorrent" ];
    shell = pkgs.bashInteractive;
    home = "/var/lib/flood";
    description = "flood Daemon user";
    isSystemUser = true;
  };

  users.groups.flood = {};

  environment.systemPackages = with pkgs; [
    mediainfo
  ];

  systemd.services.flood = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.flood}/bin/flood --rundir=/var/lib/flood --allowedpath /mnt/storage/downloads --allowedpath /var/lib --rtsocket=/run/rtorrent/rpc.sock";
      User = "flood";
      Group = "flood";
      Type = "simple";
      Restart = "on-failure";
      WorkingDirectory = "/var/lib/flood";
    };
  };

  systemd.tmpfiles.rules = [ "d '/var/lib/flood' 0755 flood flood -" ];

  services.nginx.virtualHosts."flood.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    useACMEHost = "nixbox.tv";
    
    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:3000/";
    };
  };

}