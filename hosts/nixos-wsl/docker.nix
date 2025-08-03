{ ... }:

{
  virtualisation.docker.enable = true;
  
  users.users.denzo.extraGroups = [ "docker" ];
}
