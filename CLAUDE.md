# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **nixbox.tv**, a NixOS flake-based configuration for a personal home server (host: **nixbox**). It runs a media stack (Plex, the *arr suite, rTorrent), photo/document/home-automation services (Immich, Paperless, Home Assistant), and supporting infrastructure — all declared in this repo. `TODO.md` tracks known issues and planned improvements.

## Common Development Commands

### Building and Deploying

**Deploys are interactive**: nh prompts for the remote sudo password (`wheelNeedsPassword` is on) and pipes it to `sudo --stdin` over SSH. The user runs deploys, not Claude — prepare the change, then ask the user to run `deploy`.

Inside the dev shell (`nix develop`, or automatically via direnv) a `deploy [host]` helper wraps:

```shell
nh os switch . -H nixbox --target-host nixbox --build-host nixbox
```

Build without switching (non-interactive, fine for Claude):
```shell
nh os build . -H nixbox
```

### Checks and Formatting

Run before committing:
```shell
nix flake check   # formatting + statix + deadnix + config evaluation
nix fmt           # format the tree (nixfmt, RFC style)
```

`statix.toml` disables the `empty_pattern` and `repeated_keys` lints on purpose (house style uses `{ ... }:` module signatures and dotted keys).

### Updating Dependencies

```shell
nix flake update                        # all inputs
nix flake lock --update-input nixpkgs   # one input
```

### Secret Management

Secrets live sops-encrypted in `hosts/nixbox/secrets.yaml` (age keys in `.sops.yaml`; the host decrypts with its SSH host key):

```shell
sops hosts/nixbox/secrets.yaml                          # interactive edit
sops set hosts/nixbox/secrets.yaml '["a"]["b"]' '"v"'   # non-interactive
```

## Architecture and Code Structure

### Flake layout

- `flake.nix` — inputs (nixos-unstable, home-manager, sops-nix), the `nixbox` nixosConfiguration, dev shells, checks, formatter. `specialArgs` passes `domain` ("nixbox.tv") to all modules.
- `hosts/nixbox/` — hardware config, base system (`configuration.nix`), ACME certificates, docker, networking, secrets.
- `services/` — one self-contained module per service, aggregated by `services/default.nix`.
- `users/` — home-manager configs for denzo and root.
- `overlays/` — package modifications (currently: rtorrent/libtorrent-rakshasa pinned to matching versions).

### The mkProxy helper

`services/nginx.nix` defines `mkProxy` via `_module.args`: TLS-terminating vhost with the wildcard cert, proxying to a localhost port. Services use it as:

```nix
services.nginx.virtualHosts."x.${domain}" = mkProxy 1234;
# merge extra settings with `// { ... }`, or lib.recursiveUpdate for nested keys
```

Services bind to `127.0.0.1` explicitly where the default "localhost" could resolve to `::1` and 502.

### Networking / security model

- nginx (80/443) is open in the firewall for LAN + tailnet: split-horizon DNS (Unbound on OPNsense) resolves `*.nixbox.tv` to the local IP, so web UIs work on the LAN without Tailscale; WAN stays NAT'd behind OPNsense. Tailscale remains via `trustedInterfaces = [ "tailscale0" ]`.
- Deliberate exceptions: **Plex :32400 is publicly reachable** (family remote streaming — do not "fix"), Samba serves LAN + tailnet (`hosts allow`), mosquitto 1883 and the HomeKit/mDNS ports are LAN-open, UniFi opens its device-adoption ports.
- SSH: key-only, no root login. Forgejo shares the host sshd (forced commands on the `forgejo` user).

### Storage and backups

- ZFS pool **zwembad** (2×18T mirror, single flat dataset) mounted at `/mnt/storage` — media only. Watch capacity; it runs high (~85%).
- Service state lives in `/var/lib` on the NVMe root (ext4) — not ZFS.
- Three-layer data protection: sanoid snapshots of zwembad (hourly/daily, restore from `/mnt/storage/.zfs/snapshot/`), nightly borg to a Hetzner storage box (with `postgresqlBackup` dumps at 23:15; live DB files are excluded), monthly borg verification. Backup status lands on ntfy.

### Monitoring and alerting

Netdata agent (cloud UI bundled) at `https://netdata.${domain}`; health alerts, ZED (ZFS events), scrutiny (SMART), and borg all notify the self-hosted ntfy (`https://ntfy.${domain}`, iOS via upstream ntfy.sh).

## Key Conventions

1. One module per service in `services/`, imported via `services/default.nix`
2. Reverse proxy with `mkProxy` + shared wildcard cert (`useACMEHost = domain`)
3. Media-touching services join the `mediausers` group; downloads dir is setgid `mediausers` with umask 0007 so the *arrs hardlink instead of copy
4. Secrets via sops; never commit plaintext secrets (service env vars go through `EnvironmentFile` from a sops secret)
5. `system.stateVersion` is 23.05 — never bump it casually; PostgreSQL major version is pinned by it
6. Keep `TODO.md` current when fixing or deferring known issues
