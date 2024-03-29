# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./../../services/flood.nix
      ./../../services/lidarr.nix
      ./../../services/monitoring/monitoring.nix
      ./../../services/plex.nix
      ./../../services/radarr.nix
      ./../../services/minio.nix
      ./../../services/rtorrent.nix
      ./../../services/samba.nix
      ./../../services/smartd.nix
      ./../../services/sonarr.nix
      ./../../services/ssh.nix
      ./../../services/unifi.nix
    ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "smtp/password" = {};
      "borg/ssh_private_key" = {};
      "borg/passphrase" = {};
    };
  };

  # Enable Nix Flakes
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "@wheel" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  users.extraUsers.denzo = {
    isNormalUser = true;
    home = "/home/denzo";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFcJJbDNPRxWWj/9W6NtLGfwQ9fYs+JUQJZA8e2ug9Hd"
    ];
  };

  users.groups."mediausers" = {
    # Add necessary users to the group
    members = [ "sonarr" "radarr" "lidarr" "plex" "denzo" "rtorrent" "flood" ];
  };

  # Enable ZSH as the default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Enable automatic login for the user.
  services.getty.autologinUser = "denzo";

  security.sudo.wheelNeedsPassword = false;

  networking.hostName = "nixbox";
  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi = {
    powersave = false;
  };

  networking.hostId = "84f87fcf";

  # Disable NetworkManager-wait-online as it's flaky.
  systemd.services.NetworkManager-wait-online.enable = false;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # ZFS
  services.zfs.autoScrub.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
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

  # Enable the NGINX daemon.
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
  };

  # Configure Let's Encrypt settings.
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "dutybounddead@protonmail.com";
    };
  };

  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/etc/aliases";
      port = 465;
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      tls = "on";
      auth = "login";
      tls_starttls = "off";
    };
    accounts = {
      default = {
        host = "smtp.gmail.com";
        passwordeval = "cat ${config.sops.secrets."smtp/password".path}";
        user = "denzonl@gmail.com";
        from = "denzonl@gmail.com";
      };
    };
  };

  services.zfs.zed.settings = {
    ZED_DEBUG_LOG = "/tmp/zed.debug.log";
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
    ZED_EMAIL_OPTS = "@ADDRESS@";

    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;

    ZED_USE_ENCLOSURE_LEDS = true;
    ZED_SCRUB_AFTER_RESILVER = true;
  };

  # Back up to borgbase
  services.borgbackup.jobs."nixbox" = {
    paths = [
      "/var/lib"
      "/home"
    ];
    exclude = [
      # very large paths
      "/var/lib/containers"
      "/var/lib/docker"
      "/var/lib/systemd"
      "/var/lib/libvirt"
      "/var/lib/plex/Plex Media Server/Cache"
    ];
    repo = "s4474nk7@s4474nk7.repo.borgbase.com:repo";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets."borg/passphrase".path}";
    };
    environment.BORG_RSH = "ssh -i ${config.sops.secrets."borg/ssh_private_key".path}";
    compression = "auto,lzma";
    startAt = "daily";
  };

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowPing = true;
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}

