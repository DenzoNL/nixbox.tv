{ pkgs, ... }: 

{
  services.smartd = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    smartmontools
  ];
}