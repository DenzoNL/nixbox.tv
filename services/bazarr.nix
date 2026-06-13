{ domain, mkProxy, ... }:

{
  services.bazarr.enable = true;

  services.nginx.virtualHosts."bazarr.${domain}" = mkProxy 6767;
}
