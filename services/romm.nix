{
  config,
  pkgs,
  domain,
  nixpkgs-romm,
  ...
}:

{
  # Module comes from nixpkgs PR #547607 (via the nixpkgs-romm input) until it
  # lands in nixos-unstable; services.romm doesn't exist on the main pin yet.
  imports = [ "${nixpkgs-romm}/nixos/modules/services/web-apps/romm.nix" ];

  # Metadata provider credentials in dotenv format (IGDB_CLIENT_ID,
  # IGDB_CLIENT_SECRET, SCREENSCRAPER_USER, ...).
  sops.secrets."romm/environment" = { };

  # The module hardcodes pkgs.rahasher (RetroAchievements hashing), which is
  # also new in the PR and missing from the main nixpkgs pin.
  nixpkgs.overlays = [
    (_final: prev: {
      inherit (nixpkgs-romm.legacyPackages.${prev.stdenv.hostPlatform.system}) rahasher;
    })
  ];

  services.romm = {
    enable = true;
    package = nixpkgs-romm.legacyPackages.${pkgs.stdenv.hostPlatform.system}.romm;
    # The default API port (8080) is UniFi's device-inform port.
    port = 8998;
    nginx.virtualHost = "romm.${domain}";
    environmentFile = config.sops.secrets."romm/environment".path;
  };

  # The ROM files belong on zwembad, but upstream fixes the library location
  # to ${dataDir}/library. Its layout is library/{roms,bios}/<platform>/, so
  # bind /mnt/storage/roms onto the roms half; bios and the rest of the state
  # stay on the NVMe root like other services.
  fileSystems."/var/lib/romm/library/roms" = {
    device = "/mnt/storage/roms";
    fsType = "none";
    options = [ "bind" ];
  };

  # Storage conventions: denzo drops ROMs in over samba, the setgid bit keeps
  # new files in mediausers, and romm reads/writes through group membership.
  systemd.tmpfiles.settings."10-romm"."/mnt/storage/roms".d = {
    mode = "2775";
    user = "denzo";
    group = "mediausers";
  };
  users.users.romm.extraGroups = [ "mediausers" ];

  # The module defines the vhost (frontend, mod_zip downloads, njs decode);
  # add TLS directly on it rather than chaining a second mkProxy vhost.
  services.nginx.virtualHosts."romm.${domain}" = {
    forceSSL = true;
    useACMEHost = domain;
    kTLS = true;
    # The module's "/" location uses add_header, which makes nginx drop the
    # global security headers from appendHttpConfig for that location (gixy
    # fails the config build over it). Re-declare them here. SAMEORIGIN
    # instead of the global DENY in case RomM ever frames its own player.
    locations."/".extraConfig = ''
      add_header Strict-Transport-Security $hsts_header;
      add_header 'Referrer-Policy' 'origin-when-cross-origin';
      add_header X-Frame-Options SAMEORIGIN;
      add_header X-Content-Type-Options nosniff;
    '';
  };
}
