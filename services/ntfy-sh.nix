{ ... }:

{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.nixbox.tv";
      upstream-base-url = "https://ntfy.sh"; # Necessary for iOS notifications
      listen-http = ":8085";
      behind-proxy = true;
      # Can't really load these nicely from secret files, but it's fine.
      web-push-public-key = "BPh34c4ui2eIqjwwINOHmxsoYl9jcdCBwrSzVr-FUFmlup8dKdTXqMX26odbedHw49ZqcfFvOCdILh5MQxGyniY";
      web-push-private-key = "SFLVptc_ex39zqRFGYojqyxXnRSYE3kjE3F72x6rELU";
      web-push-file = "/var/lib/ntfy-sh/webpush.db";
      web-push-email-address = "dutybounddead@protonmail.com";
    };
  };

  services.nginx.virtualHosts."ntfy.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:8085/";
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