{
  config,
  domain,
  pkgs,
  protonvpn,
  ...
}:

# MyAnonamouse ties the passkey to the IP you browse from. rtorrent announces
# from the ProtonVPN exit instead, so MAM answers "Unrecognized host/PassKey".
# Its Dynamic Seedbox endpoint registers the IP a call comes from as an extra
# allowed seedbox IP. This unit calls it from inside the proton namespace (so the
# source IP is the VPN exit) whenever the tunnel comes up, and about hourly to
# catch exit IP changes.
#
# The session (MAM > Preferences > Security) is ASN-locked to Proton (AS199218)
# with "allow dynamic seedbox" on. Its mam_id is the sops secret below. MAM can
# rotate the cookie in its responses, so the live value is kept in a curl cookie
# jar; the secret only seeds that jar, and changing the secret reseeds it.
let
  url = "https://t.myanonamouse.net/json/dynamicSeedbox.php";
  stateDir = "/var/lib/mam-seedbox";
in
{
  sops.secrets."mam/session_id" = { };

  systemd.services.mam-seedbox = {
    description = "Register the ProtonVPN exit IP with MyAnonamouse (dynamic seedbox)";
    wantedBy = [ protonvpn.unit ];
    bindsTo = [ protonvpn.unit ];
    # The default route in the namespace is added by the peer unit.
    after = [
      protonvpn.unit
      "wireguard-wg-proton-peer-nl-424.service"
    ];
    onFailure = [ "mam-seedbox-notify.service" ];
    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    script = ''
      jar=${stateDir}/cookies.txt
      seed=${stateDir}/seed.sha256
      secret=${config.sops.secrets."mam/session_id".path}

      # (Re)seed the jar from the secret on first run or when the secret changed.
      want=$(sha256sum < "$secret")
      if [ ! -s "$jar" ] || [ "$(cat "$seed" 2>/dev/null)" != "$want" ]; then
        printf '.myanonamouse.net\tTRUE\t/\tTRUE\t0\tmam_id\t%s\n' \
          "$(tr -d '[:space:]' < "$secret")" > "$jar"
        echo "$want" > "$seed"
        echo "Seeded cookie jar from the sops secret"
      fi

      # Transient failures (DNS, tunnel not passing traffic yet, 5xx) exit 75
      # and are retried; anything else is a session problem and exits 1.
      out=$(curl -sS --max-time 30 -b "$jar" -c "$jar" -w '\n%{http_code}' ${url}) || exit 75
      code=''${out##*$'\n'}
      body=''${out%$'\n'*}
      echo "HTTP $code: $(echo "$body" | jq -c . 2>/dev/null || echo "$body")"

      case "$code" in
        200) exit 0 ;;
        # "Last change too recent": an earlier call already registered an IP;
        # the next timer run (>1h later) will retry if it still differs.
        429) exit 0 ;;
        5??) exit 75 ;;
        *) exit 1 ;;
      esac
    '';
    serviceConfig = {
      Type = "oneshot";
      NetworkNamespacePath = protonvpn.netnsPath;
      # Same DNS confinement as rtorrent: resolve via Proton, not host nscd.
      BindReadOnlyPaths = [ "${protonvpn.resolvConf}:/etc/resolv.conf" ];
      InaccessiblePaths = [ "/run/nscd" ];
      StateDirectory = "mam-seedbox";
      StateDirectoryMode = "0700";
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = "2min";
      RestartPreventExitStatus = [ 1 ];
    };
    # Give up retrying transient failures after ~5 attempts; OnFailure then fires.
    startLimitIntervalSec = 900;
    startLimitBurst = 5;
  };

  # MAM rate-limits IP changes to once per rolling hour; stay just outside it.
  systemd.timers.mam-seedbox = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnActiveSec = "65min";
      OnUnitActiveSec = "65min";
    };
  };

  # Runs in the host namespace so it can reach ntfy even if the tunnel is down.
  systemd.services.mam-seedbox-notify = {
    description = "MyAnonamouse dynamic seedbox alert";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.ntfy-sh}/bin/ntfy send --title "MAM seedbox IP update failed" --priority high \
        --tags warning https://ntfy.${domain}/nixbox \
        "Registering the ProtonVPN IP with MyAnonamouse failed; MAM torrents may stop announcing. Check: journalctl -u mam-seedbox"
    '';
  };
}
