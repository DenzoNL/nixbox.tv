{ domain, mkProxy, ... }:

{
  services.prowlarr.enable = true;

  services.nginx.virtualHosts."prowlarr.${domain}" = mkProxy 9696;
}
