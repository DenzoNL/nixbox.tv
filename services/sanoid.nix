{ ... }:

{
  # Local ZFS snapshots of the media pool: fat-finger/rogue-service insurance
  # with instant restores (browse /mnt/storage/.zfs/snapshot/<name>/).
  # Snapshots are copy-on-write and only cost space for data deleted or
  # rewritten during the retention window, so keep retention short: the pool
  # is one flat dataset and the downloads/ churn is pinned along with
  # everything else. Watch usage with `zfs get usedbysnapshots zwembad`.
  services.sanoid = {
    enable = true;
    datasets."zwembad" = {
      autosnap = true;
      autoprune = true;
      hourly = 24;
      daily = 7;
      weekly = 0;
      monthly = 0;
    };
  };
}
