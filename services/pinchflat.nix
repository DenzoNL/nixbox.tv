{ config, domain, ... }:

{
  services.pinchflat = {
    enable = false;
    selfhosted = true;
    mediaDir = "/mnt/storage/youtube";
  };

  # services.nginx.virtualHosts."pinchflat.${domain}" = {
  #   locations."/" = {
  #     proxyPass = "http://localhost:${toString config.services.pinchflat.port}/";
  #     proxyWebsockets = true;
  #   };
  # };
}