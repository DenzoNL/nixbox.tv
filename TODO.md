# TODO

Findings from the July 2026 full config + log audit, ordered roughly by impact.
Check items off as they land; delete this file when empty.

## Bugs & misconfigurations

- [x] **Fix automatic garbage collection** — `gc = { ... }` sat under `nixpkgs.config` (silently ignored). Fixed via `programs.nh.clean` (weekly, `--keep 5 --keep-since 14d`) + `nix.settings.auto-optimise-store`.
- [x] **Allow Tailscale clients in Samba** — added `100.64.0.0/10` to `hosts allow`. (`services/samba.nix`)
- [x] **Make borg DB-safe** — nightly `pg_dumpall` at 23:15 via `services.postgresqlBackup`, live postgres/plex/unifi DB files excluded (covered by the dumps, Plex's dated backups, and UniFi autobackups respectively).
- [x] **Add borg pruning** — `prune.keep`: 2d within / 7 daily / 4 weekly / 6 monthly; module runs `borg compact` after. Monthly check now also verifies the 3 most recent archives.
- [x] **Fix borg notification** — postHook now distinguishes success (0) / warnings (1) / failure (>=2).
- [x] **Fix rtorrent shutdown** — `TimeoutStopSec = "5min"` so session flush isn't SIGKILLed. (`services/rtorrent.nix`)
- [x] **Order zigbee2mqtt after mosquitto** — `after`/`wants` on `mosquitto.service`.
- [x] **Fix paperless env var prefixes** — now `PAPERLESS_USE_X_FORWARD_HOST`/`_PORT`.
- [x] **Silence netdata noise** — tc plugin disabled. The ACLK `ErrAgentAlreadyConnected` turned out to be a single transient event (once in 7 days), not a loop — no action.
- [x] **Finish bifrost teardown** — already done: node no longer in the tailnet, zero references left in the repo.

## Security

- [ ] **Rotate the ntfy web-push keypair and move it to sops** — the VAPID private key is committed in plaintext (since 2024); regenerate with `ntfy webpush keys`, load via `EnvironmentFile` (`NTFY_WEB_PUSH_PRIVATE_KEY=...`). (`services/ntfy-sh.nix:16`)
- [ ] **Disable permanent Zigbee joining** — `permit_join = true` accepts any device 24/7; set `false`, pair via the frontend. (`services/home-assistant/zigbee2mqtt.nix`)
- [ ] **Add ntfy auth** — `auth-default-access = "deny-all"` + tokens; anyone on the tailnet can currently read/publish all topics.
- [ ] **Drop the legacy nginx `sslCiphers` override** — it weakens `recommendedTlsSettings` (drops ChaCha20, no effect on TLS 1.3). (`services/nginx.nix:14`)
- [ ] **Remove dead `ssl_stapling` config** — Let's Encrypt shut down OCSP in 2025. (`services/unifi.nix:29-30`)
- [ ] Consider dropping console autologin (`services.getty.autologinUser`) — with passwordless sudo, physical access = instant root. (`hosts/nixbox/configuration.nix:75`)

## Improvements

- [ ] **Enable Intel Quick Sync for Plex** — `hardware.graphics.enable = true` + `intel-media-driver`; the i5-13400's iGPU is unused and CPU transcoding pushed cores to 82°C. Also check cooling/dust. Optionally OpenVINO for Immich ML.
- [ ] **Add local ZFS snapshots** — `services.sanoid` on `zwembad`; borg covers offsite but a stray `rm` on `/mnt/storage` is currently unrecoverable.
- [ ] **Tame swap** — `zramSwap.enable = true` + `vm.swappiness = 10`; 6.6G/8.8G swap used by cold pages keeps tripping netdata's 90% alert.
- [ ] **Plan for pool capacity** — `zwembad` at 85% (2.3T free); ZFS write performance degrades past ~90%.
- [ ] **Add lint/format checks** — `nixfmt-rfc-style`, `statix`, `deadnix` in the dev shell + a `checks` flake output so `nix flake check` catches drift.
- [ ] **Update stale docs** — CLAUDE.md references `pkgsStable`/`customPkgs`/`packages/` which no longer exist; README lists 6 of ~20 services.
- [ ] **Plan PostgreSQL major upgrade** — the cluster is still on PostgreSQL 14 (pinned by `stateVersion`), which reaches end-of-life November 2026. Needs a `pg_upgrade`/dump-restore migration plus bumping `services.postgresql.package`.
- [ ] Small QoL: `smartmontools` in systemPackages (only inside scrutiny's store path today), `services.fwupd.enable`, `nix.settings.experimental-features` instead of `extraOptions`, `bat`/`dust`/`bottom`/`ripgrep`/`fd`.

## Watch (no action yet)

- sda has one ancient CRC error (cable hiccup) that makes scrutiny's nightly smartctl exit 64 — ignore unless `UDMA_CRC_Error_Count` ever rises above 1.
- `zpool upgrade` is available for zwembad but irreversible; only do it when older-tooling imports are never needed.
- Plex on :32400 is intentionally publicly reachable (remote streaming for family) — the one deliberate exception to the tailnet-only model. Keep Plex auto-updated.
