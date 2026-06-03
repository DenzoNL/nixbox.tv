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
      ];
    };

    # Forgejo lives on the apex of switchbyte.dev. Kept as a separate cert
    # from the nixbox.tv wildcard. Reuses the Porkbun credentials above
    # (account-level API keys), so no extra secret is required.
    # NOTE: Porkbun requires "API Access" to be enabled on the switchbyte.dev
    # domain itself for the DNS-01 challenge to succeed.
    certs."switchbyte.dev" = {
      domain = "switchbyte.dev";
    };
  };

  # Allow nginx to read the wildcard certificate
  users.users.nginx.extraGroups = [ "acme" ];
}