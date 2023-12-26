{ config, lib, ... }:

{
  system.activationScripts.makeZomboidDirs = lib.stringAfter [ "var" ] ''
    mkdir -p /var/lib/zomboid /var/lib/zomboid-mods
  '';

  networking.firewall.allowedTCPPorts = [ 27015 ];
  networking.firewall.allowedUDPPorts = [ 16261 16262 ];

  sops.secrets = {
    "zomboid" = { };
  };

  virtualisation.oci-containers.containers = {
    zomboid = {
      image = "danixu86/project-zomboid-dedicated-server:latest";
      autoStart = true;
      environmentFiles = [
        config.sops.secrets."zomboid".path
      ];
      ports = [
        "16261:16261/udp"
        "16262:16262/udp"
        "27015:27015"
      ];
      volumes = [
        "/var/lib/zomboid:/home/steam/Zomboid"
        "/var/lib/zomboid-mods:/home/steam/pz-dedicated/steamapps/workshop"
      ];
    };
  };
}