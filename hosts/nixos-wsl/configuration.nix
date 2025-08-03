# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ pkgs, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = "denzo";
  wsl.startMenuLaunchers = true;

  wsl.wslConf.network.generateHosts = false;
  networking.extraHosts = ''
    100.69.0.2 bifrost
  '';

  users.users.denzo.shell = pkgs.fish;
  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;
  
  # Enable nix flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Required for configuring binary caches with cachix
  nix.settings.trusted-users = [ "root" "denzo" ];

  # Prevent OOMkills by limiting the amount of concurrency while compiling
  nix.settings.cores = 10;

  environment.systemPackages = with pkgs; [
    git
    htop
    wget
  ];

  # Workaround for VSCode Remote Server
  programs.nix-ld = {
    enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-mono
    nerd-fonts.caskaydia-cove
  ];

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/nixbox.tv#nixos-wsl";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
