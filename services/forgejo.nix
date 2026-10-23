{
  config,
  lib,
  mkProxy,
  ...
}:

let
  fqdn = "switchbyte.dev";
  httpPort = 3001;
  forgejoUser = config.services.forgejo.user;
in
{
  # Runner token for the Actions runner below. This is *not* a registration
  # token: `services.forgejo-runner` wants the uuid + token pair of an already
  # registered runner, i.e. the "uuid" and "token" fields of the `.runner` file
  # the registration produced (uuid lives in the nix config, the bare token --
  # no `TOKEN=` prefix -- in secrets.yaml). To register a fresh runner, run
  # `forgejo-runner register` by hand once and copy the pair out of its
  # `.runner` file. systemd loads the file via LoadCredential=, so it can stay
  # root-owned.
  sops.secrets."forgejo/runnerToken" = { };

  # Admin bootstrap credentials. Owned by the forgejo user so the preStart
  # below (which runs as that user) can read them. NOTE: Forgejo forbids the
  # username "admin", so forgejo/adminUser must be something else.
  sops.secrets."forgejo/adminUser".owner = forgejoUser;
  sops.secrets."forgejo/adminPassword".owner = forgejoUser;

  services.forgejo = {
    enable = true;

    # Use the existing PostgreSQL instance via the local socket (peer auth).
    # The module contributes its own ensureDatabases/ensureUsers entries and
    # the postgresql ordering, so no password or extra secret is needed.
    database.type = "postgres";

    settings = {
      server = {
        DOMAIN = fqdn;
        ROOT_URL = "https://${fqdn}/";
        # Bind to loopback; nginx terminates TLS and proxies in.
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = httpPort;

        # Git over SSH is served by the host's OpenSSH (runs as the `forgejo`
        # user, which the module creates). Forgejo manages its own
        # authorized_keys with forced commands at runtime.
        START_SSH_SERVER = false;
        SSH_DOMAIN = fqdn;
        SSH_PORT = 22;
      };

      # Single-user instance reachable only over Tailscale: no public sign-ups.
      service.DISABLE_REGISTRATION = true;

      # Enable Forgejo Actions so the runner below has something to talk to.
      actions.ENABLED = true;
    };
  };

  # Idempotently ensure the admin user exists on every start. preStart is a
  # `types.lines` option, so this concatenates *after* the Forgejo module's own
  # preStart (config generation + DB migrations) and runs as the forgejo user.
  # `create` fails harmlessly once the user exists (|| true); uncomment the
  # change-password line to rotate the password from the secret.
  systemd.services.forgejo.preStart =
    let
      adminCmd = "${lib.getExe config.services.forgejo.package} admin user";
      userFile = config.sops.secrets."forgejo/adminUser".path;
      pwdFile = config.sops.secrets."forgejo/adminPassword".path;
    in
    ''
      ${adminCmd} create --admin --must-change-password=false \
        --email "admin@${fqdn}" \
        --username "$(tr -d '\n' < ${userFile})" \
        --password "$(tr -d '\n' < ${pwdFile})" \
        || true
      # ${adminCmd} change-password \
      #   --username "$(tr -d '\n' < ${userFile})" \
      #   --password "$(tr -d '\n' < ${pwdFile})" || true
    '';

  # Forgejo Actions runner with the Docker executor: every job runs in an
  # ephemeral container (Docker is enabled in hosts/nixbox/docker.nix; the
  # module adds the service to the `docker` group and orders it after
  # docker.service). State lives in /var/lib/forgejo-runner/nixbox.
  services.forgejo-runner.instances."nixbox" = {
    enable = true;
    settings = {
      runner.labels = [
        "docker:docker://node:24"
      ];
      server.connections.default = {
        # The runner hands this URL to the jobs: actions/checkout clones from
        # it *inside* the job container, where "localhost" is the container
        # itself. So it must be the externally reachable name, not loopback --
        # the containers reach nginx on the host's LAN/tailnet IP (443 is open
        # on all interfaces). Registering against loopback made every CI job
        # fail at checkout with "Failed to connect to localhost port 3001".
        url = "https://${fqdn}/";
        uuid = "adf8a363-e6f6-40ac-85ee-a8c70ea1a564";
      };
    };
    secrets.server.connections.default.token_url = config.sops.secrets."forgejo/runnerToken".path;
  };

  # Tailnet-only reverse proxy. useACMEHost overrides mkProxy's nixbox.tv
  # default so the switchbyte.dev certificate is served instead.
  services.nginx.virtualHosts."${fqdn}" = mkProxy httpPort // {
    useACMEHost = fqdn;
    # Allow large git pushes / LFS uploads over HTTP.
    extraConfig = ''
      client_max_body_size 512M;
    '';
  };
}
