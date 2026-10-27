{ lib, protonvpn, ... }:

{
  services.rtorrent = {
    enable = true;
    downloadDir = "/mnt/storage/downloads";

    # Rest of the config is the upstream module default; mkAfter overrides its
    # umask. 0007 = new downloads 660 (group rw, no world): group-write lets the
    # *arr apps hardlink them (see below), everything reaches them via mediausers.
    # The listen port comes from the ProtonVPN NAT-PMP lease (see protonvpn.nix);
    # until the first lease the module default (50000) applies, unreachable.
    configText = lib.mkAfter ''
      system.umask.set = 0007
      try_import = ${protonvpn.portFile}
    '';
  };

  systemd.services.rtorrent = {
    # Peer traffic only through ProtonVPN: the namespace has no other uplink, so
    # rtorrent goes offline instead of leaking when the tunnel is down. No WAN
    # port forward or firewall opening needed; Proton forwards the port.
    bindsTo = [ protonvpn.unit ];
    after = [ protonvpn.unit ];
    serviceConfig = {
      NetworkNamespacePath = protonvpn.netnsPath;
      # Tracker lookups via Proton's DNS: hide nscd (it resolves in the host
      # namespace, i.e. outside the tunnel) and swap in a namespace resolv.conf.
      BindReadOnlyPaths = [ "${protonvpn.resolvConf}:/etc/resolv.conf" ];
      InaccessiblePaths = [ "/run/nscd" ];

      # rtorrent flushes session state for every torrent on shutdown, which can
      # take well over the default 90s stop timeout; systemd would then SIGKILL it
      # and risk corrupting the session.
      TimeoutStopSec = "5min";
    };
  };

  # setgid + group mediausers so new torrents inherit the shared group (rtorrent's
  # own group is `rtorrent`). This lets the *arr apps hardlink downloads into the
  # library instead of copying, and keeps that group on the hardlinked files.
  systemd.tmpfiles.rules = [
    "d /mnt/storage/downloads 2770 denzo mediausers -"
  ];
}
