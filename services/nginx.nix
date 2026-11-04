{ lib, domain, ... }:

let
  # The IOT VLAN (Google Nest, Apple TV, consoles, ...). OPNsense lets it reach
  # nixbox on 80/443, but every vhost refuses it unless listed below.
  iotNet = "10.0.40.0/24";
  iotAllowedVhosts = [
    "home.${domain}" # Home Assistant app on non-trusted phones
    "romm.${domain}" # Argosy on the AYN Thor
    "jellyfin.${domain}"
  ];
in
{
  # Default-deny IOT on every vhost, including ones that don't use mkProxy and
  # ones added later. Done by extending the vhost submodule instead of mkProxy,
  # because several services overwrite `extraConfig` with `//`.
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          config.extraConfig = lib.mkIf (!lib.elem name iotAllowedVhosts) (
            lib.mkBefore ''
              deny ${iotNet};
            ''
          );
        }
      )
    );
  };

  config = {
    # LAN clients reach the web UIs directly: OPNsense/Unbound split-horizon DNS
    # resolves *.nixbox.tv to the local IP, so 80/443 must be open beyond the
    # tailscale0 trusted interface. WAN is still NAT'd behind OPNsense.
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.nginx = {
      enable = true;

      # Use recommended settings (including the cipher suites; an AES256-only
      # override used to live here but only weakened them)
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      appendHttpConfig = ''
        # Add HSTS header with preloading to HTTPS requests.
        # Adding this header to HTTP requests is discouraged
        map $scheme $hsts_header {
            https   "max-age=31536000; includeSubdomains; preload";
        }
        add_header Strict-Transport-Security $hsts_header;

        # Minimize information leaked to other domains
        add_header 'Referrer-Policy' 'origin-when-cross-origin';

        # Disable embedding as a frame
        add_header X-Frame-Options DENY;

        # Prevent injection of code in other mime types (XSS Attacks)
        add_header X-Content-Type-Options nosniff;
      '';
    };

    # Helper for the common vhost: terminate TLS with the wildcard cert and proxy
    # to a localhost port. Services use it as:
    #   services.nginx.virtualHosts."x.${domain}" = mkProxy 1234;
    # and merge extra vhost settings with `// { ... }` when needed.
    _module.args.mkProxy = port: {
      forceSSL = true;
      useACMEHost = domain;
      kTLS = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}/";
        proxyWebsockets = true;
      };
    };
  };
}
