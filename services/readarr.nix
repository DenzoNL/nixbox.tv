{ ... }:

{
  services.readarr = {
    enable = true;
  };

  services.nginx.virtualHosts."readarr.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:8787/";
      proxyWebsockets = true;
    };
  };
}