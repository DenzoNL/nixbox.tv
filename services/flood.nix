{ config, domain, ... }:

{
  services.flood = {
    enable = true;
    extraArgs = [ "--allowedpath /mnt/storage/downloads --rtsocket=${config.services.rtorrent.rpcSocket}" ];
  };

  systemd.services.flood = { 
    serviceConfig = {
      # Grant Flood access to the rtorrent RPC socket
      SupplementaryGroups = [ "rtorrent" ];
      # Grant Flood RW access to the download directory
      ReadWritePaths = [ "/mnt/storage/downloads" ];
    };
  };

  services.nginx.virtualHosts."flood.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:3000/";
    };
  };

}