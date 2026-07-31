# TODO

- [ ] Drop `pnpm-9.15.9` from `permittedInsecurePackages` in `hosts/nixbox/configuration.nix` once nixpkgs migrates karakeep off EOL pnpm 9 (karakeep currently breaks with pnpm 10): https://github.com/NixOS/nixpkgs/issues/529285
- [ ] Drop the meilisearch `preStart` sed workaround in `services/karakeep.nix` once the nixpkgs module writes `upgrade_db` instead of the removed `experimental_dumpless_upgrade` key (meilisearch 1.51 renamed the flag)
