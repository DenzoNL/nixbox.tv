# TODO

- [ ] Drop the `nodejs_22` override on `services.karakeep.package` in `services/karakeep.nix` once nixos-unstable ships a Node 24.x that fixes the ObjectWrap cleanup-hook regression from 24.19.0 (https://github.com/nodejs/node/pull/63642 — aborts NAN-style addons like better-sqlite3 with `Assertion failed: (env) != nullptr` during GC; took karakeep down 2026-08-13→15). Keep the `Restart = "on-failure"` hardening either way.

- [ ] Drop the `fastapi-pagination` patch in `overlays/modifications.nix` (and `overlays/fastapi-pagination-old-fastapi.patch`) once `python3Packages.fastapi` 0.141.1 reaches nixos-unstable: https://github.com/NixOS/nixpkgs/pull/548924 (merged to *staging* 2026-08-11, ~1300 rebuilds). 0.141.1 ships the private `_get_body_field`/`_get_flat_body_params` that fastapi-pagination 0.15.16 wants, so the patched fallback branch stops executing — the patch goes inert on its own, it just becomes dead weight.
