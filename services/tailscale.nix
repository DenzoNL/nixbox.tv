{ config, ... }:

{
  sops.secrets."tailscale/authKey" = { };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets."tailscale/authKey".path;
    # Keep the system resolver on the LAN (OPNsense/Unbound via DHCP) instead
    # of letting tailscaled take over /etc/resolv.conf. The tailnet pushes a
    # NextDNS DoH resolver as the global nameserver; when that is unreachable
    # (as happened 2026-10-23) tailscaled's forwarder wedges and *all* name
    # resolution on this box dies, taking the CI runner, backups and updates
    # with it. Unbound already serves the split-horizon names this host needs;
    # only MagicDNS (*.ts.net) names stop resolving here, which nothing uses.
    extraSetFlags = [ "--accept-dns=false" ];
  };

  # Trust Tailscale interface for incoming connections
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
