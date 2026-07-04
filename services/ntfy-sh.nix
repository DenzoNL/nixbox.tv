{
  config,
  domain,
  mkProxy,
  ...
}:

let
  ntfyPort = 8085;
in
{
  # NTFY_WEB_PUSH_PRIVATE_KEY=<key>; env vars override the generated
  # server.yml, so the private key stays out of the nix store and repo.
  sops.secrets."ntfy/environment" = { };
  systemd.services.ntfy-sh.serviceConfig.EnvironmentFile =
    config.sops.secrets."ntfy/environment".path;

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.${domain}";
      upstream-base-url = "https://ntfy.sh"; # Necessary for iOS notifications
      listen-http = ":${toString ntfyPort}";
      behind-proxy = true;
      web-push-public-key = "BHcyJpF4wVKMHwOWeIXKLyOtUxRlotRX_z-DdPujAav3EzHUc_vsbJGwmhozCYbvq3yJeXSN4rcy_VuSoENu71Y";
      web-push-file = "/var/lib/ntfy-sh/webpush.db";
      web-push-email-address = "dutybounddead@protonmail.com";
    };
  };

  services.nginx.virtualHosts."ntfy.${domain}" = mkProxy ntfyPort // {
    extraConfig = ''
      proxy_connect_timeout 3m;
      proxy_send_timeout 3m;
      proxy_read_timeout 3m;

      client_max_body_size 0; # Stream request body to backend
    '';
  };
}
