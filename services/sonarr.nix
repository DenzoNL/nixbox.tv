{ domain, mkProxy, ... }:

{
  services.sonarr.enable = true;

  services.nginx.virtualHosts."sonarr.${domain}" = mkProxy 8989;
}
