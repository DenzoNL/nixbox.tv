{ config, ... }:

{
  # Keeps the A record for matrix.switchbyte.dev pointed at this box's dynamic
  # WAN IP (Matrix federation depends on it; see services/tuwunel.nix).
  #
  # ddns-updater's config is a single JSON document that embeds the Porkbun
  # API keys, so the whole file is the secret. Same account-level credentials
  # as acme/porkbun, but lego wants env-file format and ddns-updater wants
  # JSON, so they can't share one secret. Expected value (one line):
  #   {"settings":[{"provider":"porkbun","domain":"matrix.switchbyte.dev","api_key":"pk1_...","secret_api_key":"sk1_...","ip_version":"ipv4","ttl":600}]}
  sops.secrets."ddns-updater/config" = { };

  services.ddns-updater = {
    enable = true;
    environment = {
      # The secret JSON is handed to the (DynamicUser) service via systemd's
      # credential mechanism below; %d expands to the credentials directory.
      CONFIG_FILEPATH = "%d/config.json";
      PERIOD = "5m";
      # Status web UI: loopback only (reach it via SSH port-forward). 8448 is
      # the only publicly forwarded port on this host, but there's no reason
      # to show this UI on the LAN either. Not the default :8000, which
      # audiobookshelf already occupies.
      LISTENING_ADDRESS = "127.0.0.1:8001";
    };
  };

  systemd.services.ddns-updater.serviceConfig.LoadCredential = [
    "config.json:${config.sops.secrets."ddns-updater/config".path}"
  ];
}
