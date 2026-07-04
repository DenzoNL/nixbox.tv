{ pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    # Explicit major version (stateVersion 23.05 would otherwise pin the
    # EOL PostgreSQL 14). Major upgrades are dump/restore: see git history
    # of UPGRADE-PG17.md for the runbook used for 14 -> 17.
    package = pkgs.postgresql_17;
    ensureDatabases = [ "hass" ];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
  };
}
