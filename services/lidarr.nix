{ domain, mkProxy, ... }:

{
  services.lidarr.enable = true;

  services.nginx.virtualHosts."lidarr.${domain}" = mkProxy 8686;
}
