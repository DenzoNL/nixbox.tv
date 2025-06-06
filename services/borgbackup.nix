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
}