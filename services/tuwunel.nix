{ config, ... }:

let
  # Matrix IDs live on the apex (@user:switchbyte.dev); the actual traffic is
  # delegated to matrix.switchbyte.dev:8448 via an SRV record at Porkbun
  # (_matrix._tcp.switchbyte.dev -> 10 0 8448 matrix.switchbyte.dev). The apex
  # itself points at a tailnet IP (Forgejo) and is not publicly reachable, so
  # .well-known delegation is not an option.
  serverName = "switchbyte.dev";
  fqdn = "matrix.${serverName}";
  # The tuwunel module's default listener: 127.0.0.1/::1 only.
  tuwunelPort = 6167;
in
{
  # Token for the one-time admin bootstrap below. Owned by the tuwunel user so
  # the server can read it (registration_token_file is read at startup).
  sops.secrets."tuwunel/registrationToken".owner = config.services.matrix-tuwunel.user;

  services.matrix-tuwunel = {
    enable = true;
    settings.global = {
      server_name = serverName;
      allow_federation = true;

      # One-time admin bootstrap: flip allow_registration to true, deploy,
      # register the account with the token from tuwunel/registrationToken
      # (the first registered user automatically becomes server admin), then
      # flip it back to false and deploy again. The token gate means nobody
      # else can sneak in while the window is open.
      allow_registration = false;
      registration_token_file = config.sops.secrets."tuwunel/registrationToken".path;
    };
  };

  # Federation entry point. Port 8448 is the only port forwarded on the router;
  # 80/443 stay LAN/tailnet-only as elsewhere on this host.
  networking.firewall.allowedTCPPorts = [ 8448 ];

  # TLS terminator for tuwunel. One vhost, two listeners:
  #  - 8448: federation and public client access (the router forwards this).
  #    SRV-delegated peers connect with SNI/Host = switchbyte.dev, not the SRV
  #    target; that still lands here because this is the only server block on
  #    8448 (nginx's default for the port), and the cert covers the apex.
  #  - 443: client access from LAN/tailnet (not publicly reachable).
  # mkProxy is not used because it forces the nixbox.tv default listeners and
  # a port-80 redirect block, neither of which applies here.
  services.nginx.virtualHosts."${fqdn}" = {
    onlySSL = true;
    useACMEHost = serverName;
    kTLS = true;
    listen = [
      {
        addr = "0.0.0.0";
        port = 8448;
        ssl = true;
      }
      {
        addr = "[::]";
        port = 8448;
        ssl = true;
      }
      {
        addr = "0.0.0.0";
        port = 443;
        ssl = true;
      }
      {
        addr = "[::]";
        port = 443;
        ssl = true;
      }
    ];
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString tuwunelPort}";
      proxyWebsockets = true;
    };
    # Keep nginx's request cap in sync with tuwunel's (bytes).
    extraConfig = ''
      client_max_body_size ${toString config.services.matrix-tuwunel.settings.global.max_request_size};
    '';
  };
}
