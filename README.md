# nixbox.tv

A NixOS flake for my personal home server, inspired by [Saltbox](https://github.com/saltyorg/Saltbox).

## Services

**Media**: Plex, Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, rTorrent + Flood, Audiobookshelf

**Apps**: Immich (photos), Paperless (documents), Karakeep (bookmarks), Forgejo + Actions runner (git), The Lounge (IRC)

**Home automation**: Home Assistant, Mosquitto, Zigbee2MQTT

**Infrastructure**: nginx (tailnet-only reverse proxy, wildcard TLS), Tailscale, Samba, UniFi, ntfy (notifications), Netdata (monitoring), Scrutiny (SMART), BorgBackup + sanoid ZFS snapshots

## Setup

Fork & clone this git repository to your home directory:

```shell
$ git clone git@github.com:<USERNAME>/nixbox.tv.git
```

> :warning: **Don't use my hardware-configuration.nix, generate your own!**: Be very careful here!

Create an `age` key from your SSH private key to encrypt/decrypt secrets:

```
nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
```

Make any changes to the configuration as necessary and deploy it to the host configured in [flake.nix](./flake.nix):

```shell
$ nh os switch . -H nixbox --target-host nixbox --build-host nixbox
```

Or, from inside the dev shell (`nix develop`), use the `deploy` helper:

```shell
$ deploy          # deploys nixbox (prompts for the sudo password)
```

## Development

The dev shell ships `nixfmt`, `statix` and `deadnix`. Before committing:

```shell
$ nix fmt          # format
$ nix flake check  # formatting + lints + config evaluation
```
