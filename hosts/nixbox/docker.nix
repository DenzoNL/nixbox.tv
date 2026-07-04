{ ... }:

{
  virtualisation = {
    docker = {
      enable = true;
    };
    oci-containers = {
      backend = "docker";
    };
  };

  # Intentionally nobody in the docker group besides the Forgejo runner (the
  # module adds itself): docker group membership is root-equivalent and would
  # bypass the sudo password. Use `sudo docker` for manual poking.
}