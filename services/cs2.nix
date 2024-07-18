{ ... }:

{
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.containers."cs2" = {
    image = "cs2-modded-server";
    autoStart = false;
    volumes = [
      "cs2-volume:/home/steam/"
      "/home/denzo/custom_files:/home/custom_files/"
      "/home/denzo/game:/home/game/"
    ];
  };
}
