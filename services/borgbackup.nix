 { config, domain, pkgs, ... }:

 {
  sops.secrets = {
    "borg/ssh_private_key" = {};
    "borg/passphrase" = {};
  };

  services.borgbackup.jobs."nixbox" = {
    paths = [
      "/var/lib"
      "/home"
      "/mnt/storage/docs"
      "/mnt/storage/music"
    ];
    exclude = [
      # very large paths
      "/var/lib/containers"
      "/var/lib/systemd"
      "/var/lib/libvirt"
      "/var/lib/plex/Plex Media Server/Cache"
      "/var/lib/lidarr/.config/Lidarr/MediaCover"
    ];
    repo = "ssh://u406496@u406496.your-storagebox.de:23/./backups/nixbox";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets."borg/passphrase".path}";
    };
    environment.BORG_RSH = "ssh -i ${config.sops.secrets."borg/ssh_private_key".path}";
    compression = "auto,lzma";
    startAt = "daily";
    postHook = ''
      if [ $exitStatus -eq 2 ]; then
        ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox "BorgBackup: nixbox backup failed with errors"
      else
        ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox "BorgBackup: nixbox backup completed succesfully with exit status $exitStatus"
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
        
        # Repository-only check (fast, checks repository integrity)
        if ${pkgs.borgbackup}/bin/borg check --repository-only; then
          ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox \
            "BorgBackup: Monthly repository check passed ✓"
        else
          ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox \
            "BorgBackup: Monthly repository check FAILED! Manual intervention required"
          exit 1
        fi
        
        # Optional: Archive check (slower, checks archive metadata)
        # Uncomment the following if you want more thorough monthly checks:
        # if ${pkgs.borgbackup}/bin/borg check --archives-only --last 3; then
        #   echo "Archive check passed"
        # else
        #   ${pkgs.ntfy-sh}/bin/ntfy send https://ntfy.${domain}/nixbox \
        #     "BorgBackup: Archive check FAILED!"
        #   exit 1
        # fi
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