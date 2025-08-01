# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, domain, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./certificate.nix
      ./docker.nix
      ./monitoring.nix
      ./networking.nix
      ./../../services/audiobookshelf.nix
      ./../../services/bazarr.nix
      ./../../services/borgbackup.nix
      ./../../services/filebrowser.nix
      ./../../services/flood.nix
      ./../../services/home-assistant
      ./../../services/homepage.nix
      ./../../services/immich.nix
      ./../../services/lidarr.nix
      ./../../services/nginx.nix
      ./../../services/ntfy-sh.nix
      ./../../services/paperless.nix
      ./../../services/pinchflat.nix
      ./../../services/plex.nix
      ./../../services/prowlarr.nix
      ./../../services/radarr.nix
      ./../../services/readarr.nix
      ./../../services/rtorrent.nix
      ./../../services/samba.nix
      ./../../services/scrutiny.nix
      ./../../services/sonarr.nix
      ./../../services/ssh.nix
      ./../../services/tailscale.nix
      ./../../services/tautulli.nix
      ./../../services/the-lounge.nix
      ./../../services/unifi.nix
    ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  # Enable Nix Flakes
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "@wheel" ];
  };

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "aspnetcore-runtime-6.0.36"
      "aspnetcore-runtime-wrapped-6.0.36"
      "dotnet-sdk-6.0.428"
      "dotnet-sdk-wrapped-6.0.428"
    ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  users.extraUsers.denzo = {
    isNormalUser = true;
    home = "/home/denzo";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFcJJbDNPRxWWj/9W6NtLGfwQ9fYs+JUQJZA8e2ug9Hd"
    ];
  };

  users.groups."mediausers" = {
    # Add necessary users to the group
    members = [
      "audiobookshelf"
      "bazarr"
      "denzo"
      "lidarr"
      "plex"
      "radarr"
      "readarr"
      "rtorrent"
      "sonarr"
    ];
  };

  # Enable Fish as the default shell
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # Enable automatic login for the user.
  services.getty.autologinUser = "denzo";

  security.sudo.wheelNeedsPassword = false;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Disable bluetooth
  hardware.bluetooth.enable = false;
  boot.blacklistedKernelModules = ["bluetooth"];

  # ZFS
  services.zfs.autoScrub.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    eza
    git
    htop
    iftop
    ncdu
    pciutils
    rclone
    screen
    wget
  ];

  # Enable iperf3 daemon.
  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };

  services.zfs.zed.settings = {
    ZED_DEBUG_LOG = "/tmp/zed.debug.log";
    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;

    ZED_USE_ENCLOSURE_LEDS = true;
    ZED_SCRUB_AFTER_RESILVER = true;

    ZED_NTFY_TOPIC = "nixbox";
    ZED_NTFY_URL = "https://ntfy.${domain}";
  };
  
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}

