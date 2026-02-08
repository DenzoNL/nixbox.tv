{ ... }:

{
  # REQUIRED: Incus mandates nftables (assertion fails otherwise)
  networking.nftables.enable = true;
  # Prevent NixOS from flushing Incus's nftables rules (required for stateVersion < 23.11)
  networking.nftables.flushRuleset = false;

  virtualisation.incus = {
    enable = true;
    ui.enable = true;

    preseed = {
      # Directory-based storage pool on ext4 root filesystem
      storage_pools = [{
        name = "default";
        driver = "dir";
        config.source = "/var/lib/incus/storage-pools/default";
      }];

      # NAT bridge network (VM uses this for internet, Tailscale for direct access)
      networks = [{
        name = "incusbr0";
        type = "bridge";
        config = {
          "ipv4.address" = "10.10.10.1/24";
          "ipv4.nat" = "true";
          "ipv6.address" = "none";
        };
      }];

      # Default profile for VMs
      profiles = [{
        name = "default";
        devices = {
          root = {
            path = "/";
            pool = "default";
            type = "disk";
            size = "50GiB";
          };
          eth0 = {
            name = "eth0";
            network = "incusbr0";
            type = "nic";
          };
        };
      }];
    };
  };

  # User access
  users.extraUsers.denzo.extraGroups = [ "incus-admin" ];

  # IP forwarding for NAT
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Allow DNS and DHCP on the Incus bridge for VMs to get network config
  networking.firewall.interfaces.incusbr0 = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 67 ];
  };

  # Trust the Incus bridge to allow forwarded traffic from VMs
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
}
