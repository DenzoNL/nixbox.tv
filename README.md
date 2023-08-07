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

Make any changes to the configuration as necessary and deploy it to the host configured in [flake.nix](./flake.nix):

```shell
$ deploy
```