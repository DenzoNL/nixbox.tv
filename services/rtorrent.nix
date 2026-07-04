{ lib, ... }:

{
  services.rtorrent = {
    enable = true;
    downloadDir = "/mnt/storage/downloads";
    openFirewall = true;

    # Rest of the config is the upstream module default; mkAfter overrides its
    # umask. 0007 = new downloads 660 (group rw, no world): group-write lets the
    # *arr apps hardlink them (see below), everything reaches them via mediausers.
    configText = lib.mkAfter ''
      system.umask.set = 0007
    '';
  };

  # rtorrent flushes session state for every torrent on shutdown, which can take
  # well over the default 90s stop timeout; systemd would then SIGKILL it and
  # risk corrupting the session.
  systemd.services.rtorrent.serviceConfig.TimeoutStopSec = "5min";

  # setgid + group mediausers so new torrents inherit the shared group (rtorrent's
  # own group is `rtorrent`). This lets the *arr apps hardlink downloads into the
  # library instead of copying, and keeps that group on the hardlinked files.
  systemd.tmpfiles.rules = [
    "d /mnt/storage/downloads 2770 denzo mediausers -"
  ];
}
