{ pkgs, domain, ... }:

{
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi;
    openFirewall = true;
    maximumJavaHeapSize = 2048;
    mongodbPackage = pkgs.mongodb-ce;
  };

  services.nginx.virtualHosts."unifi.${domain}" = {
    forceSSL = true;
    useACMEHost = domain;
    kTLS = true;

    locations."/" = {
      proxyPass = "https://localhost:8443/";
    };

    # The UniFi backend serves self-signed HTTPS on 8443, so we proxy over TLS
    # without verifying its certificate. Client-facing TLS (protocols/ciphers)
    # comes from the global recommendedTlsSettings in services/nginx.nix.
    extraConfig = ''
      proxy_set_header X-SSL 'on';
      proxy_ssl_verify off;
      proxy_ssl_session_reuse on;

      proxy_buffering off;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $server_addr;
      proxy_set_header Referer $server_addr;
      proxy_set_header Origin $server_addr; 
      proxy_set_header X-Forwarded-Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    '';
  };
}
