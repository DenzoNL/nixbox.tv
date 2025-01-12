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

  users.extraUsers.denzo.extraGroups = [ "docker" ];
}