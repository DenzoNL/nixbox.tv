{ config, ... }:

{
  sops.secrets."tailscale/authKey" = { };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets."tailscale/authKey".path;
  };

  # Trust Tailscale interface for incoming connections
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
