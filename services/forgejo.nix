{
  config,
  lib,
  mkProxy,
  pkgs,
  ...
}:

let
  fqdn = "switchbyte.dev";
  httpPort = 3001;
  forgejoUser = config.services.forgejo.user;
in
{
  # Registration token for the Actions runner below. Generate it once Forgejo
  # is up (Site Administration -> Actions -> Runners -> Create new runner, or
  # `forgejo actions generate-runner-token`) and store it in secrets.yaml.
  # The file is loaded as a systemd EnvironmentFile, so the secret value must
  # be in the form:  TOKEN=<token>
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

  # Forgejo Actions runner. Registers against the local instance over loopback
  # and uses the Docker executor, so every job runs in an ephemeral container
  # (Docker is already enabled in hosts/nixbox/docker.nix). The module adds the
  # service to the `docker` group and orders it after docker.service.
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances."nixbox" = {
      enable = true;
      name = "nixbox";
      url = "http://localhost:${toString httpPort}";
      tokenFile = config.sops.secrets."forgejo/runnerToken".path;
      labels = [
        "docker:docker://node:24"
      ];
    };
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
