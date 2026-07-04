# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  domain,
  pkgs,
  ...
}:

{
  # The host modules plus the full service set (services/default.nix aggregates
  # every service module).
  imports = [
    ./hardware-configuration.nix
    ./certificate.nix
    ./docker.nix
    ./networking.nix
    ../../services
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
    settings = {
      trusted-users = [ "@wheel" ];
      # Deduplicate identical store files via hardlinks
      auto-optimise-store = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Automatic cleanup of old generations and unreferenced store paths
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 14d";
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
      "rtorrent"
      "sonarr"
    ];
  };

  # Enable Fish as the default shell
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # Enable automatic login for the user.
  services.getty.autologinUser = "denzo";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Disable bluetooth
  hardware.bluetooth.enable = false;
  boot.blacklistedKernelModules = [ "bluetooth" ];

  # Intel Quick Sync on the UHD 730 iGPU: userspace drivers for hardware
  # video transcoding (Plex, Immich) instead of burning CPU.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # iHD VA-API driver (Gen11+)
      intel-compute-runtime # OpenCL, used by Plex for HDR tone mapping
      vpl-gpu-rt # oneVPL runtime for QSV-native consumers
    ];
  };

  # ZFS
  services.zfs.autoScrub.enable = true;

  # Compressed in-RAM swap, higher priority than the disk partition (which
  # stays as overflow). Idle service pages park here compressed instead of
  # accumulating on the NVMe. Metrics show no thrashing (swap I/O ~0), so
  # swappiness stays at the default.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  # No swap readahead: it only benefits rotational swap, zram reads are instant
  boot.kernel.sysctl."vm.page-cluster" = 0;

  # With zram the kernel OOM killer can trigger too late (compressing into a
  # RAM-backed device under pressure), risking a lockup; systemd-oomd kills
  # the worst cgroup early. The daemon runs by default but monitors nothing
  # until slices opt in.
  systemd.oomd = {
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    beets
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
