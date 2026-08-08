{
  config,
  pkgs,
  lib,
  domain,
  spanreed,
  mkProxy,
  ...
}:

let
  port = 3200;
  package = spanreed.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # Matrix account + web-login credentials, as a dotenv blob under
  # "spanreed/environment" in hosts/nixbox/secrets.yaml:
  #
  #   MATRIX_HOMESERVER_URL=https://matrix.switchbyte.dev
  #   MATRIX_USERNAME=@you:switchbyte.dev
  #   MATRIX_PASSWORD=...
  #   SPANREED_WEB_USERNAME=...
  #   SPANREED_WEB_PASSWORD_HASH=$argon2id$...   # `spanreed hash-password`
  #
  # Kept here (not in `environment` below) because it's public-repo config:
  # the Matrix identity and the login username/hash stay out of git. systemd
  # reads EnvironmentFile as root, before dropping to the service user.
  sops.secrets."spanreed/environment" = { };

  # The homeserver (tuwunel) runs on this box, but its public name resolves —
  # via this host's Tailscale MagicDNS — to the WAN IP, which hairpins to the
  # OPNsense router and answers 443 with the router's own cert (a name
  # mismatch that fails spanreed's TLS). Pin the name to the local nginx,
  # which terminates TLS for it with the valid cert. (Verified: a request to
  # 127.0.0.1:443 with SNI matrix.switchbyte.dev returns the real cert + the
  # client-versions endpoint.)
  networking.extraHosts = "127.0.0.1 matrix.switchbyte.dev";

  systemd.services.spanreed = {
    description = "spanreed — self-hosted Matrix web client";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    # Non-secret process config; identity/secrets come from the sops file.
    environment = {
      HOST = "127.0.0.1"; # localhost only; nginx terminates TLS in front
      PORT = toString port;
      SPANREED_DATA_DIR = "/var/lib/spanreed";
      SPANREED_COOKIE_SECURE = "1"; # served over HTTPS by nginx
    };

    serviceConfig = {
      ExecStart = lib.getExe package;
      EnvironmentFile = config.sops.secrets."spanreed/environment".path;
      Restart = "on-failure";
      RestartSec = 5;

      # State (sqlite crypto store, session.json, caches) in /var/lib/spanreed.
      # sqlite is single-process; systemd keeps exactly one instance.
      DynamicUser = true;
      StateDirectory = "spanreed";

      # Hardening — a conservative set known-safe for a network service.
      # (MemoryDenyWriteExecute / SystemCallFilter left off for the first
      # deploy; can tighten once it's confirmed working.)
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      LockPersonality = true;
    };
  };

  # TLS vhost at spanreed.nixbox.tv → the localhost port. SSE works through the
  # default proxy: spanreed sends `X-Accel-Buffering: no` (so nginx streams
  # without buffering) and a keep-alive every ~15s (so the stream never idles
  # out). The longer read timeout is belt-and-braces for the long-lived stream.
  services.nginx.virtualHosts."spanreed.${domain}" = mkProxy port // {
    extraConfig = ''
      proxy_read_timeout 1h;
    '';
  };
}
