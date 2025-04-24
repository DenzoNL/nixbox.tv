{ domain, ... }:

{
  services.readarr = {
    enable = true;
  };

  services.nginx.virtualHosts."readarr.${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:8787/";
      proxyWebsockets = true;
    };
  };
}