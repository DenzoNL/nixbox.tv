{ ... }:

{
  virtualisation.oci-containers.containers.streammaster = {
    image = "senexcrenshaw/streammaster:main-1.0.1.7";
    ports = ["127.0.0.1:7095:7095"];
    volumes = [
      "/var/lib/streammaster:/config"
      "/var/lib/streammaster/tv-logos:/config/tv-logos"
    ];
  };

  services.nginx.virtualHosts."streammaster.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:7095/";
      proxyWebsockets = true;
    };
  };
}