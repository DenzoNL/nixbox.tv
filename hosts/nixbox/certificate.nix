{ config, ... }:

{
  sops.secrets."acme/cloudflare" = {};

  # Configure Let's Encrypt DNS-01 challenge
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "dutybounddead@protonmail.com";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."acme/cloudflare".path;
      dnsPropagationCheck = true;
    };
    # Create and auto-renew wildcard certificate for Nixbox.tv
    certs."nixbox.tv" = { 
      domain = "*.nixbox.tv";
    };
  };

  # Allow nginx to read the wildcard certificate
  users.users.nginx.extraGroups = [ "acme" ];
}