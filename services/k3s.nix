{
  services.k3s = {
    enable = false;
    role = "server";
    extraFlags = [
      "--disable=traefik"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  ];
}