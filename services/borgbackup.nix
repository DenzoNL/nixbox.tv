 { config, domain, pkgs, ... }:

 {
  sops.secrets = {
    "borg/ssh_private_key" = {};
    "borg/passphrase" = {};
  };

  # Nightly pg_dumpall shortly before the borg run: borg then backs up the
  # dumps instead of live datafiles (which change mid-backup and would be
  # inconsistent on restore).
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    startAt = "*-*-* 23:15:00";
  };

  services.borgbackup.jobs."nixbox" = {
    paths = [
      "/var/lib"
      "/var/backup/postgresql"
      "/home"
      "/mnt/storage/docs"
      "/mnt/storage/music"
    ];
    exclude = [
      # very large paths
      "/var/lib/containers"
      "/var/lib/docker"
      "/var/lib/systemd"
      "/var/lib/libvirt"
      "/var/lib/plex/Plex Media Server/Cache"
      "/var/lib/lidarr/.config/Lidarr/MediaCover"

      # live databases (they change mid-backup and restore inconsistent):
      # postgres is covered by the pg_dumpall above, plex by its own scheduled
      # DB backups (dated com.plexapp.plugins.library.db-YYYY-MM-DD files in
      # the same directory, which are still included), unifi by its autobackups
      # in /var/lib/unifi/data/backup.
      "/var/lib/postgresql"
      "/var/lib/unifi/data/db"
      "/var/lib/plex/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
      "/var/lib/plex/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.blobs.db"
      "sh:/var/lib/plex/Plex Media Server/Plug-in Support/Databases/*.db-wal"
      "sh:/var/lib/plex/Plex Media Server/Plug-in Support/Databases/*.db-shm"
    ];
    # Thin out old archives (the module runs `borg compact` afterwards, so
    # pruned space is actually freed on the storage box)
    prune.keep = {
      within = "2d";
      daily = 7;
      weekly = 4;
      monthly = 6;
    };
    repo = "ssh://u406496@u406496.your-storagebox.de:23/./backups/nixbox";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets."borg/passphrase".path}";
    };
    environment.BORG_RSH = "ssh -i ${config.sops.secrets."borg/ssh_private_key".path}";
    compression = "auto,lzma";
    startAt = "daily";
    # Borg exit codes: 0 = success, 1 = completed with warnings, >=2 = error.
    postHook = ''
      if [ $exitStatus -eq 0 ]; then
        ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox "BorgBackup: nixbox backup completed successfully"
      elif [ $exitStatus -eq 1 ]; then
        ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox "BorgBackup: nixbox backup completed with warnings, check the journal"
      else
        ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox "BorgBackup: nixbox backup FAILED with exit status $exitStatus"
      fi
    '';
  };

  # Treat exit status 1 as success for the backup job
  # so that it doesn't trigger prometheus alerts
  systemd.services."borgbackup-job-nixbox".serviceConfig = {
    SuccessExitStatus = "0 1";
  };

  # Monthly verification of backup integrity
  systemd.services."borgbackup-check-nixbox" = {
    description = "Verify BorgBackup repository integrity";
    after = [ "network.target" ];
    environment = {
      BORG_REPO = "ssh://u406496@u406496.your-storagebox.de:23/./backups/nixbox";
      BORG_RSH = "ssh -i ${config.sops.secrets."borg/ssh_private_key".path}";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "borg-check" ''
        export BORG_PASSPHRASE=$(cat ${config.sops.secrets."borg/passphrase".path})

        echo "Starting BorgBackup repository verification..."

        # Repository integrity (fast), then archive metadata of the three most
        # recent archives (slower, catches corrupt archives a repo check misses)
        if ${pkgs.borgbackup}/bin/borg check --repository-only \
            && ${pkgs.borgbackup}/bin/borg check --archives-only --last 3; then
          ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox \
            "BorgBackup: Monthly repository check passed ✓"
        else
          ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox \
            "BorgBackup: Monthly repository check FAILED! Manual intervention required"
          exit 1
        fi
      '';
      User = "root";
    };
  };

  systemd.timers."borgbackup-check-nixbox" = {
    description = "Monthly BorgBackup verification";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      RandomizedDelaySec = "4h";  # Randomize to avoid load spikes
      Persistent = true;  # Run if system was offline when scheduled
    };
  };
}