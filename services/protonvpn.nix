{ config, pkgs, ... }:

# ProtonVPN WireGuard tunnel inside its own network namespace. Services that set
# `NetworkNamespacePath = "/run/netns/proton"` only see `lo` + `wg-proton`, so
# they cannot reach the internet except through the tunnel (built-in kill
# switch). The WireGuard UDP socket itself stays in the init namespace and uses
# the normal uplink. Unix sockets (e.g. rtorrent's RPC socket) keep working
# across the namespace boundary, so Flood/*arrs need no changes.
let
  ns = "proton";
  gateway = "10.2.0.1";
  iproute = "${pkgs.iproute2}/bin/ip";

  # rtorrent imports this file; it holds the port leased via NAT-PMP.
  portFile = "/var/lib/protonvpn/rtorrent-port.rc";
in
{
  _module.args.protonvpn = {
    netnsPath = "/run/netns/${ns}";
    inherit portFile;
    # The namespace has no nscd or Tailscale MagicDNS; resolve via Proton's DNS.
    resolvConf = pkgs.writeText "resolv.conf-${ns}" ''
      nameserver ${gateway}
    '';
    unit = "wireguard-wg-proton.service";
  };

  sops.secrets."protonvpn/wireguard_key" = { };

  systemd.services."netns-${ns}" = {
    description = "Network namespace for ProtonVPN-confined services";
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${iproute} netns add ${ns}"
        "${iproute} -n ${ns} link set lo up"
      ];
      ExecStop = "${iproute} netns delete ${ns}";
    };
  };

  # Proton config "nixbox-rtorrent" (NL#424, P2P, NAT-PMP on). The config has no
  # IPv6 address, so only route IPv4; IPv6 has no route at all in the namespace.
  networking.wireguard.interfaces.wg-proton = {
    interfaceNamespace = ns;
    ips = [ "10.2.0.2/32" ];
    privateKeyFile = config.sops.secrets."protonvpn/wireguard_key".path;
    peers = [
      {
        name = "nl-424";
        publicKey = "OJv7H1H34Og2BqBwrUdTQPXZPD0oG1rh7wkMWAgGUAQ=";
        endpoint = "103.69.224.5:51820";
        allowedIPs = [ "0.0.0.0/0" ];
        persistentKeepalive = 25;
      }
    ];
  };

  systemd.services.wireguard-wg-proton = {
    bindsTo = [ "netns-${ns}.service" ];
    after = [ "netns-${ns}.service" ];
  };

  # Proton forwards one public port per tunnel via NAT-PMP; the lease lasts 60s
  # and must be renewed. The port usually stays the same while the tunnel is up;
  # when it changes, write it to portFile and restart rtorrent so it listens on it.
  systemd.services.protonvpn-natpmp = {
    description = "Keep the ProtonVPN NAT-PMP port lease alive";
    # The default route is added by the peer unit, so wait for that one too.
    bindsTo = [ "wireguard-wg-proton.service" ];
    after = [
      "wireguard-wg-proton.service"
      "wireguard-wg-proton-peer-nl-424.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.libnatpmp
      pkgs.gnused
      config.systemd.package
    ];
    script = ''
      while true; do
        natpmpc -a 1 0 udp 60 -g ${gateway} >/dev/null
        port=$(natpmpc -a 1 0 tcp 60 -g ${gateway} \
          | sed -n 's/^Mapped public port \([0-9]*\) protocol TCP.*/\1/p')
        if [ -z "$port" ]; then
          echo "NAT-PMP lease failed" >&2
          exit 1
        fi
        want="network.listen.port.range.set = $port-$port"
        if [ "$(cat ${portFile} 2>/dev/null)" != "$want" ]; then
          echo "Forwarded port is now $port"
          echo "$want" > ${portFile}
          systemctl try-restart rtorrent.service
        fi
        sleep 45
      done
    '';
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/${ns}";
      StateDirectory = "protonvpn";
      Restart = "always";
      RestartSec = 10;
    };
  };
}
