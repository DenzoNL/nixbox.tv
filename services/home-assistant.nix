{ ... }:

{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "Europe/Berlin";
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      extraOptions = [
        "--pull=always"
        "--network=host" 
      ];
    };
  };

  services.nginx.virtualHosts."home.nixbox.tv" = {
    # Enable Let's Encrypt
    forceSSL = true;
    enableACME = true;

    http2 = true;

    extraConfig = ''
        proxy_buffering off;
    '';

    locations."/" = {
      proxyPass = "http://localhost:8123/";
      proxyWebsockets = true;
    };
  };
}