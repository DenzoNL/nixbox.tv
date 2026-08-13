# TODO

- [ ] Drop the `fastapi-pagination` patch in `overlays/modifications.nix` (and `overlays/fastapi-pagination-old-fastapi.patch`) once `python3Packages.fastapi` 0.141.1 reaches nixos-unstable: https://github.com/NixOS/nixpkgs/pull/548924 (merged to *staging* 2026-08-11, ~1300 rebuilds). 0.141.1 ships the private `_get_body_field`/`_get_flat_body_params` that fastapi-pagination 0.15.16 wants, so the patched fallback branch stops executing — the patch goes inert on its own, it just becomes dead weight.
