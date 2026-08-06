# TODO

- [ ] Matrix (tuwunel) go-live, in order: create Porkbun records (`_matrix._tcp.switchbyte.dev` SRV `10 0 8448 matrix.switchbyte.dev.` + initial `matrix` A record), forward TCP 8448 on OPNsense to nixbox, deploy, register the admin account (one-time `allow_registration` toggle documented in `services/tuwunel.nix`), then verify with https://federationtester.matrix.org/ against `switchbyte.dev`
- [ ] Drop `pnpm-9.15.9` from `permittedInsecurePackages` in `hosts/nixbox/configuration.nix` once nixpkgs migrates karakeep off EOL pnpm 9 (karakeep currently breaks with pnpm 10): https://github.com/NixOS/nixpkgs/issues/529285
- [ ] Drop the meilisearch `preStart` sed workaround in `services/karakeep.nix` once the nixpkgs module writes `upgrade_db` instead of the removed `experimental_dumpless_upgrade` key (meilisearch 1.51 renamed the flag)
