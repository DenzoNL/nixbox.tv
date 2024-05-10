{ pkgs,... }:

{
  services.transmission = {
    enable = true;
    openFirewall = true;
    package = pkgs.transmission_4;
    webHome = pkgs.flood-for-transmission;
    settings = {
      download-dir = "/mnt/storage/downloads";
      rpc-host-whitelist-enabled = true;
      rpc-host-whitelist = "torrents.nixbox.tv";
    };
  };

  services.nginx.virtualHosts."torrents.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    useACMEHost = "nixbox.tv";

    http2 = true;

    locations."/" = {
      proxyPass = "http://localhost:9091/";
      proxyWebsockets = true;
    };
  };
}