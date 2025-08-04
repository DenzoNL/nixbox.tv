{ config, domain, ... }:

{
  sops.secrets."acme/porkbun" = {};

  # Configure Let's Encrypt DNS-01 challenge
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "dutybounddead@protonmail.com";
      dnsProvider = "porkbun";
      environmentFile = config.sops.secrets."acme/porkbun".path;
      dnsPropagationCheck = true;
    };
    # Create and auto-renew wildcard certificate
    certs."${domain}" = { 
      domain = domain;
      extraDomainNames = [
        "*.${domain}"
        "public.immich.${domain}"
      ];
    };
  };

  # Allow nginx to read the wildcard certificate
  users.users.nginx.extraGroups = [ "acme" ];
}