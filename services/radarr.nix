{ domain, mkProxy, ... }:

{
  services.radarr.enable = true;

  services.nginx.virtualHosts."radarr.${domain}" = mkProxy 7878;
}
