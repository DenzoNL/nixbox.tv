 { config, ... }:

 {
  sops.secrets = {
    "borg/ssh_private_key" = {};
    "borg/passphrase" = {};
  };

  services.borgbackup.jobs."nixbox" = {
    paths = [
      "/var/lib"
      "/home"
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
  };
}