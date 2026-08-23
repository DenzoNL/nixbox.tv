{
  domain,
  mkProxy,
  ...
}:

{
  services.karakeep = {
    enable = true;
    # No nodejs override here: upstream nixpkgs now pins karakeep to Node 22
    # itself (the 24.19.0 ObjectWrap regression that crashed better-sqlite3),
    # and the package no longer takes a `nodejs` argument.
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
