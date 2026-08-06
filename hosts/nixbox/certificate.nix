{ config, domain, ... }:

{
  sops.secrets."acme/porkbun" = { };

  # Configure Let's Encrypt DNS-01 challenge
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "dutybounddead@protonmail.com";
      dnsProvider = "porkbun";
      environmentFile = config.sops.secrets."acme/porkbun".path;
      dnsPropagationCheck = true;
      # Split-horizon DNS: the LAN resolver overrides nixbox.tv and returns
      # nothing for its SOA/NS, so lego's zone detection walks up to the "tv"
      # TLD and porkbun rejects the challenge record ("Invalid domain").
      # Use a public resolver for zone detection and propagation checks.
      dnsResolver = "9.9.9.9:53";
    };
    # Create and auto-renew wildcard certificate
    certs."${domain}" = {
      inherit domain;
      extraDomainNames = [
        "*.${domain}"
      ];
    };

    # Forgejo lives on the apex of switchbyte.dev; Matrix federation
    # (services/tuwunel.nix) is served on matrix.switchbyte.dev:8448. Kept as a
    # separate cert from the nixbox.tv wildcard. Reuses the Porkbun credentials
    # above (account-level API keys), so no extra secret is required.
    # The wildcard SAN covers matrix.switchbyte.dev, and the apex SAN is what
    # SRV-delegated federation validates against (remote servers check the
    # cert on 8448 against the server_name, not the SRV target).
    # NOTE: Porkbun requires "API Access" to be enabled on the switchbyte.dev
    # domain itself for the DNS-01 challenge to succeed.
    certs."switchbyte.dev" = {
      domain = "switchbyte.dev";
      extraDomainNames = [
        "*.switchbyte.dev"
      ];
    };
  };

  # Allow nginx to read the wildcard certificate
  users.users.nginx.extraGroups = [ "acme" ];
}
