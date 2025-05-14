{ pkgs, ... }:

let
  hostName = "bifrost";
in
{
  imports = [
    ./certificate.nix
    ./monitoring
    ./../../services/nginx.nix
    ./../../services/tailscale.nix
  ];

  nix.settings = {
    experimental-features = "nix-command flakes";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  environment.systemPackages = with pkgs; [
    comma
    git
    htop
    vim
  ];
  
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "ext4";
  };
  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
    }
  ];
  
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.configurationLimit = 5;
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "ext4" ];
  
  users.users = {
    root.hashedPassword = "!"; # Disable root login
    denzo = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFcJJbDNPRxWWj/9W6NtLGfwQ9fYs+JUQJZA8e2ug9Hd"
      ];
    };
  };

  # Enable ZSH as the default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  
  security.sudo.wheelNeedsPassword = false;
  
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  
  networking.firewall.allowedTCPPorts = [ 22 80 443];
  networking.hostName = hostName;
  
  system.stateVersion = "24.11";
}