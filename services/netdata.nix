{ config, domain, pkgs, ... }:

{
  services.netdata = {
    enable = true;

    # The default nixpkgs netdata ships without the web dashboard (only swagger
    # files), so the agent returns "File does not exist" at /. withCloudUi bundles
    # the local agent UI (incl. the systemd-journal Logs explorer).
    package = pkgs.netdata.override { withCloudUi = true; };

    # Only nginx should reach the agent; the upstream module sets no default
    # web binding, so without this Netdata listens on all interfaces.
    config.web."bind to" = "127.0.0.1";

    # Route all health alerts to the self-hosted ntfy on a dedicated topic.
    # health_alarm_notify.conf fully replaces the stock file, so start from the
    # package's copy and append our overrides (it's sourced bash, last wins).
    configDir."health_alarm_notify.conf" = pkgs.runCommand "health_alarm_notify.conf" { } ''
      cat ${config.services.netdata.package}/share/netdata/conf.d/health_alarm_notify.conf > $out
      cat >> $out <<'EOF'

      # --- nixbox overrides ---
      SEND_NTFY="YES"
      DEFAULT_RECIPIENT_NTFY="https://ntfy.${domain}/netdata"
      SEND_EMAIL="NO"
      EOF
    '';
  };

  services.nginx.virtualHosts."netdata.${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:19999/";
      proxyWebsockets = true;
    };
  };
}
