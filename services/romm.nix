{
  config,
  domain,
  ...
}:

{
  # Metadata provider credentials in dotenv format (IGDB_CLIENT_ID,
  # IGDB_CLIENT_SECRET, SCREENSCRAPER_USER, ...).
  #
  # ScreenScraper needs two credential pairs: the per-user account
  # (SCREENSCRAPER_USER/_PASSWORD) and RomM's registered API developer account
  # (SCREENSCRAPER_DEV_ID/_DEV_PASSWORD). Upstream bakes the dev pair into its
  # docker images as build args from CI secrets, so the nixpkgs build has them
  # empty and every API call fails. They are carried in this secret instead;
  # re-extract from the published image if scraping starts 4xx-ing:
  #   docker inspect rommapp/romm:<version> -f '{{json .Config.Env}}'
  sops.secrets."romm/environment" = { };

  services.romm = {
    enable = true;
    # The default API port (8080) is UniFi's device-inform port.
    port = 8998;
    nginx.virtualHost = "romm.${domain}";
    environmentFile = config.sops.secrets."romm/environment".path;

    # Upstream announced these as the defaults their compose file should have
    # shipped with: one gunicorn worker makes the UI feel unresponsive while a
    # scan runs, and a single scan worker leaves the box idle. Both are plain
    # env vars here — bin/romm folds WEB_SERVER_CONCURRENCY into
    # GUNICORN_CMD_ARGS, and SCAN_WORKERS is read by backend/config.
    extraEnvironment = {
      WEB_SERVER_CONCURRENCY = "3";
      SCAN_WORKERS = "2";

      # Hash-based identification against hasheous.org. This is the whole
      # configuration surface: RomM authenticates as an application with a key
      # hardcoded in hasheous_handler.py, so there is no per-user credential to
      # supply and nothing for this to put in the secret.
      HASHEOUS_API_ENABLED = "true";
    };
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
