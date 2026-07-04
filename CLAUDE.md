# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **nixbox.tv**, a NixOS flake-based configuration for personal media server infrastructure. The project uses declarative configuration to manage the nixbox host running various media services like Plex, Sonarr, Radarr, and supporting infrastructure.

## Common Development Commands

### Building and Deploying

Inside the dev shell (`nix develop`) a `deploy` helper wraps the command below — it targets nixbox.

Deploy configuration using `nh` (provided in the dev shell). It builds and activates on the remote host and shows a package diff before switching:
```shell
# Deploy to nixbox host (media server)
nh os switch . -H nixbox --target-host nixbox --build-host nixbox
```

Notes:
- `-H/--hostname` selects the `nixosConfiguration` (replaces the `.#<host>` attribute path).
- Deploys prompt for the remote sudo password (nh pipes it to `sudo --stdin` over SSH), so they are interactive — the user runs them, not Claude.

Build configuration without switching:
```shell
nh os build . -H nixbox
```

### Updating Dependencies

Update flake inputs:
```shell
nix flake update
```

Update specific input:
```shell
nix flake lock --update-input nixpkgs
```

### Secret Management

This project uses SOPS for secret management. Secrets are stored in `hosts/*/secrets.yaml` files.

Edit secrets for the host:
```shell
sops hosts/nixbox/secrets.yaml
```

Generate age key from SSH key (required for initial setup):
```shell
nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
```

### Development Shell

Enter development shell with necessary tools:
```shell
nix develop
```

## Architecture and Code Structure

### Hosts

- **nixbox** (`hosts/nixbox/`): The media server hosting all media services (Plex, *arr suite, torrent client) and supporting infrastructure.

### Services

Services are modularized in `services/` directory. Each service is a self-contained NixOS module that:
- Configures the service daemon
- Sets up nginx reverse proxy with SSL (using Let's Encrypt)
- Manages firewall rules
- Handles data directories and permissions

Key service patterns:
- All services use the `mediausers` group for shared media access
- Services expose themselves at `https://<service>.${domain}` where domain is "nixbox.tv"
- Services requiring persistent data use ZFS datasets mounted at `/mnt/<service>`

### Module System

The flake uses NixOS modules with special arguments:
- `domain`: Base domain name (nixbox.tv) used across all services
- `pkgsStable`: Stable nixpkgs for services requiring specific versions
- `customPkgs`: Custom packages defined in `packages/`

### Networking

- **Security Model**: All services are only accessible via Tailscale VPN (not publicly exposed)
- Internal services communicate via Tailscale mesh network
- Public access through nginx reverse proxy with automatic SSL (only for explicitly public services)
- Firewall rules managed per-service
- LAN network: 192.168.0.0/24

### Monitoring

Monitoring runs on nixbox via Netdata (`services/netdata.nix`):
- Local Netdata agent with the bundled cloud UI, proxied at `https://netdata.${domain}`
- Health alerts routed to the self-hosted ntfy instance

## Key Conventions

1. **Service Configuration**: Always import services as NixOS modules in host configuration files
2. **SSL Certificates**: Use shared wildcard certificate via `useACMEHost = "${domain}"`
3. **Data Storage**: Use ZFS datasets for service data, mounted at `/mnt/<service>`
4. **User Management**: Add service users to `mediausers` group for shared media access
5. **Secrets**: Store in host-specific `secrets.yaml`, reference via `config.sops.secrets.<name>`
6. **Reverse Proxy**: All services should be proxied through nginx with forced SSL