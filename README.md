# nixbox.tv 

A Nix Flake for my personal media server, inspired by [Saltbox](https://github.com/saltyorg/Saltbox).

## Services

Nixbox.tv is configured with the following services:

- Plex
- Sonarr
- Radarr
- Lidarr
- rTorrent
- Flood (UI for rTorrent)

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
$ nh os switch . -H nixbox --target-host nixbox --build-host nixbox -e passwordless
```

Or, from inside the dev shell (`nix develop`), use the `deploy` helper (defaults to the nixbox host):

```shell
$ deploy          # deploys nixbox
$ deploy bifrost  # deploys bifrost
```

