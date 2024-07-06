{ pkgs, ... }:

{
  services.code-server = {
    enable = true;
    auth = "none"; # Protected by Tailscale
    disableTelemetry = true;
    disableUpdateCheck = true;
    proxyDomain = "code.nixbox.tv";
    user = "denzo";
    extraPackages = with pkgs; [
      nil
    ];
  };

  services.nginx.virtualHosts."code.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:4444/";
      proxyWebsockets = true;
    };
  };
}