# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **nixbox.tv**, a NixOS flake-based configuration for personal media server infrastructure. The project uses declarative configuration to manage multiple hosts with various media services like Plex, Sonarr, Radarr, and supporting infrastructure.

## Common Development Commands

### Building and Deploying

Deploy configuration to a specific host:
```shell
# Deploy to nixbox host (main media server)
nixos-rebuild switch --fast --flake .#nixbox --target-host nixbox --build-host nixbox --use-remote-sudo

# Deploy to bifrost host (monitoring/proxy server) 
nixos-rebuild switch --fast --flake .#bifrost --target-host bifrost --build-host bifrost --use-remote-sudo

# Deploy to boneweevil host (WSL instance)
nixos-rebuild switch --fast --flake .#boneweevil
```

Build configuration without switching:
```shell
nixos-rebuild build --flake .#nixbox
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

Edit secrets for a host:
```shell
sops hosts/nixbox/secrets.yaml
sops hosts/bifrost/secrets.yaml
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

The system supports three distinct hosts, each with specific responsibilities:

- **nixbox** (`hosts/nixbox/`): Primary media server hosting all media services (Plex, *arr suite, torrent client)
- **bifrost** (`hosts/bifrost/`): Kubernetes cluster with monitoring stack (Prometheus, Grafana, Loki) and public-facing services
- **boneweevil** (`hosts/boneweevil/`): WSL development instance with Docker support

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

- Internal services communicate via Tailscale mesh network
- Public access through nginx reverse proxy with automatic SSL
- Firewall rules managed per-service

### Monitoring

Bifrost host runs complete monitoring stack:
- Prometheus for metrics collection
- Grafana for visualization
- Loki for log aggregation
- AlertManager for alerting
- Custom Prometheus rules in `hosts/bifrost/monitoring/prometheus-rules/`

## Key Conventions

1. **Service Configuration**: Always import services as NixOS modules in host configuration files
2. **SSL Certificates**: Use shared wildcard certificate via `useACMEHost = "${domain}"`
3. **Data Storage**: Use ZFS datasets for service data, mounted at `/mnt/<service>`
4. **User Management**: Add service users to `mediausers` group for shared media access
5. **Secrets**: Store in host-specific `secrets.yaml`, reference via `config.sops.secrets.<name>`
6. **Reverse Proxy**: All services should be proxied through nginx with forced SSL