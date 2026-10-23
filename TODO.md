# TODO

- [ ] Drop the `netdata` entry in `overlays/modifications.nix` once nixpkgs substitutes `GOPROXY` repo-wide instead of only in `packaging/cmake/Modules/NetdataGoTools.cmake`. netdata 2.11.0 added a "Compressing SNMP trap profile pack" rule in `CMakeLists.txt` that runs `go run ./cmd/snmptrapprofilegen` with `GOPROXY=https://proxy.golang.org,direct` hardcoded, so it tries to hit the network and fails in the sandbox. Hydra's free build only passes because ninja happens to populate `$GOPATH/pkg/mod` first; our `withCloudUi = true` build is unfree, never cached, and always builds locally — so it always loses that race. (`NetdataIBMPlugin.cmake` has the same unsubstituted line, harmless while that plugin is off.)

- [ ] Jellyfin is running alongside Plex as a trial (`services/jellyfin.nix`, `https://jellyfin.nixbox.tv`) because of recurring Plex trouble. Decide which one stays: if Jellyfin wins, retire Plex (its public :32400 firewall exception, the `plex` Home Assistant component, the Plex-specific borg excludes) and give Jellyfin the same treatment (consider the `jellyfin` HA component, and opening UDP 7359 for LAN client discovery); if Plex wins, drop the module and `/var/lib/jellyfin`.

- [ ] Once the Forgejo runner is confirmed working under `services.forgejo-runner` (state now in `/var/lib/forgejo-runner/nixbox`), delete the old `/var/lib/gitea-runner` directory (orphaned state + actions cache of the removed `services.gitea-actions-runner` module).

- [ ] `nix fmt` is broken: newer Nix invokes the formatter with no arguments, and the flake's formatter is bare `nixfmt`, which then reads an empty stdin ("unexpected end of input"). Switch the formatter to `nixfmt-tree` (treefmt wrapper) so `nix fmt` formats the whole tree again; `nix flake check` still passes because the format check lists the files itself.

- [ ] Drop the `unifi` entry in `overlays/modifications.nix` once nixpkgs' unifi package adds the gcc runtime libs (`libstdc++`, `libgcc_s`) that `libubnt_webrtc_jni.so` (new in 10.6.106) needs; without them autoPatchelf fails and the whole system build dies at `unit-unifi.service`.
