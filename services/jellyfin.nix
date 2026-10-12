{ domain, mkProxy, ... }:

{
  # Trial run alongside Plex (see TODO.md). Both read the same libraries on
  # /mnt/storage through the mediausers group; nothing is shared between them.
  services.jellyfin = {
    enable = true;

    # Intel Quick Sync on the UHD 730 iGPU via VA-API, same device Immich uses.
    # The module adds a DeviceAllow for it; the video/render groups below cover
    # the device file permissions. These settings only seed encoding.xml on the
    # first start (forceEncodingConfig is off), after which the dashboard
    # (Playback -> Transcoding) is the source of truth.
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    transcoding = {
      enableHardwareEncoding = true;
      # Alder Lake (Gen12 Xe-LP) decode: everything except VP8 (dropped in
      # Gen12) and 12-bit HEVC RExt (Arc and newer only).
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        hevcRExt10bit = true;
        mpeg2 = true;
        vc1 = true;
        vp9 = true;
        av1 = true;
      };
      # Gen12 encodes H.264/HEVC in hardware, AV1 only from Arc onwards.
      hardwareEncodingCodecs.hevc = true;
    };
  };

  users.users.jellyfin.extraGroups = [
    "video"
    "render"
  ];

  # Jellyfin listens on 0.0.0.0:8096, but only the proxy (and tailscale0, as a
  # trusted interface) can reach it: the firewall stays closed, so there is no
  # LAN auto-discovery (UDP 7359) — enter https://jellyfin.nixbox.tv in clients.
  services.nginx.virtualHosts."jellyfin.${domain}" = mkProxy 8096 // {
    extraConfig = ''
      # Per the upstream nginx example: uploads are small, and buffering the
      # stream segments through nginx only adds latency.
      client_max_body_size 20M;
      proxy_buffering off;
    '';
  };

  # Regenerable artwork/NFO cache; the Plex and Lidarr equivalents are
  # excluded too. The live SQLite database stays in (Jellyfin has no scheduled
  # DB backup of its own), so a restore may need a library rescan.
  services.borgbackup.jobs."nixbox".exclude = [ "/var/lib/jellyfin/metadata" ];
}
