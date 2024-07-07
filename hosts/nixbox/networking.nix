{ ... }:

{
  networking = {
    hostName = "nixbox";
    # Ensure when using ZFS that a pool isn’t imported accidentally on a wrong machine.
    hostId = "84f87fcf";

    firewall = {
      allowPing = true;
    };
  };
}