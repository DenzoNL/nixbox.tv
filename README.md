# nixbox.tv 

A Nix Flake for my personal media server. Currently, it is a work-in-progress and not suited for re-use on other systems unless you know what you are doing.

## Setup

Fork & clone this git repository to your home directory:

```shell
$ nix-shell -p git && git clone git@github.com:<USERNAME>/nixbox.tv.git 
```

> :warning: **Don't use my hardware-configuration.nix, generate your own!**: Be very careful here!

Make any changes to the configuration as necessary and deploy it to the host configured in [flake.nix](./flake.nix):

```shell
$ deploy
```

## Shell aliases

```shell
# Updates flake.lock
$ update

# Rebuilds system from flake
$ rebuild
```

## TODO

### Services
- [x] NGINX Reverse Proxy with Let's Encrypt
- [x] Plex
- [x] Sonarr
- [x] Radarr
- [x] Lidarr
- [X] Rtorrent
- [X] Flood
- [x] Grafana/Prometheus/Loki/Promtail
- [ ] Tailscale
- [ ] Overseerr

### Miscellanous
- [ ] Secrets
- [ ] Extract stuff to variables
- [ ] ZSH shell (maybe using home manager)
- [ ] Refactor/restructure Nix files to something that makes sense
