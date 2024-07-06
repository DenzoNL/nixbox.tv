{ ... }:

{
  services.bazarr = {
    enable = true;
  };

  services.nginx.virtualHosts."bazarr.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:6767/";
      proxyWebsockets = true;
    };
  };
}