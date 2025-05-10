{ domain, ... }:

let 
  ntfyPort = 8085;
in
{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.${domain}";
      upstream-base-url = "https://ntfy.sh"; # Necessary for iOS notifications
      listen-http = ":${toString ntfyPort}";
      behind-proxy = true;
      # Can't really load these nicely from secret files, but it's fine.
      web-push-public-key = "BPh34c4ui2eIqjwwINOHmxsoYl9jcdCBwrSzVr-FUFmlup8dKdTXqMX26odbedHw49ZqcfFvOCdILh5MQxGyniY";
      web-push-private-key = "SFLVptc_ex39zqRFGYojqyxXnRSYE3kjE3F72x6rELU";
      web-push-file = "/var/lib/ntfy-sh/webpush.db";
      web-push-email-address = "dutybounddead@protonmail.com";
    };
  };

  services.nginx.virtualHosts."ntfy.${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ntfyPort}/";
      proxyWebsockets = true;
    };

    extraConfig = ''
      proxy_connect_timeout 3m;
      proxy_send_timeout 3m;
      proxy_read_timeout 3m;

      client_max_body_size 0; # Stream request body to backend
    '';
  };
}