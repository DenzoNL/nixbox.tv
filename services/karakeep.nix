{
  domain,
  mkProxy,
  pkgs,
  ...
}:

{
  services.karakeep = {
    enable = true;
    # Node 24.19.0 added cleanup hooks to node::ObjectWrap
    # (https://github.com/nodejs/node/pull/63642), which makes NAN-style
    # addons like better-sqlite3 abort with "Assertion failed: (env) !=
    # nullptr" during GC. Build/run on Node 22 LTS until a fixed Node 24.x
    # reaches nixos-unstable, then drop this override (see TODO.md).
    package = pkgs.karakeep.override { nodejs = pkgs.nodejs_22; };
    browser = {
      enable = true;
    };
    meilisearch = {
      enable = true;
    };
    extraEnvironment = {
      PORT = "8765";
      DISABLE_NEW_RELEASE_CHECK = "true";
    };
  };

  # The upstream module sets no restart policy, so a crash leaves the vhost
  # 502ing until someone notices.
  systemd.services.karakeep-web.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
  };
  systemd.services.karakeep-workers.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
  };

  services.nginx.virtualHosts."karakeep.${domain}" = mkProxy 8765;
}
