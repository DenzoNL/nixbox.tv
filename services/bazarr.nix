{ domain, ... }:

{
  services.bazarr = {
    enable = true;
  };

  services.nginx.virtualHosts."bazarr.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:6767/";
      proxyWebsockets = true;
    };
  };
}