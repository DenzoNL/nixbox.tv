{
  domain,
  lib,
  mkProxy,
  ...
}:

{
  services.karakeep = {
    enable = true;
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

  # meilisearch 1.51 renamed --experimental-dumpless-upgrade to --upgrade-db,
  # but the NixOS module still writes the old key into config.toml, which the
  # new binary rejects as an unknown field. Rewrite the key after the module's
  # preStart installs the config, with bash builtins only: the unit's seccomp
  # filter (~@resources) kills sed. Drop once the nixpkgs module catches up.
  systemd.services.meilisearch.preStart = lib.mkAfter ''
    config="$RUNTIME_DIRECTORY/config.toml"
    content=$(< "$config")
    printf '%s\n' "''${content//experimental_dumpless_upgrade/upgrade_db}" > "$config"
  '';

  services.nginx.virtualHosts."karakeep.${domain}" = mkProxy 8765;
}
