{
  config,
  domain,
  mkProxy,
  ...
}:

{
  services.immich = {
    enable = true;
    # Bind to IPv4 loopback so it matches the nginx proxy target (mkProxy uses
    # 127.0.0.1); the default "localhost" can resolve to ::1 and cause a 502.
    host = "127.0.0.1";
    # Let the sandboxed service reach the iGPU for VA-API transcoding (also
    # enable it in the admin UI: Video Transcoding -> Acceleration API: VAAPI).
    # The unit's PrivateDevices sandbox hides /dev otherwise, so group
    # membership alone would not suffice.
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };

  # Belt and braces for the device file permissions (render nodes are
  # currently world-rw, but that's not guaranteed to stay that way).
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  services.nginx.virtualHosts."immich.${domain}" = mkProxy config.services.immich.port // {
    extraConfig = ''
      # Allow large file uploads
      client_max_body_size 50000M;

      # Configure timeout
      proxy_read_timeout 600s;
      proxy_send_timeout 600s;
      send_timeout       600s;
    '';
  };
}
