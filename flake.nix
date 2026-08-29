# /etc/nixos/flake.nix
{
  description = "Nixbox.tv Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Self-hosted Matrix web client, built from its own flake. Public repo on
    # the (LAN/tailnet-only) forgejo — the URL isn't a secret; outsiders just
    # can't reach it. Deliberately does NOT follow our nixpkgs: spanreed's
    # crane dep cache (~490 crates, 7-9 min) is keyed on its own pinned
    # rustc/stdenv, so following would invalidate it on every nixpkgs bump
    # here even when nothing about spanreed changed. Both track
    # nixos-unstable, so the pins converge on spanreed's own flake updates.
    spanreed = {
      url = "git+https://switchbyte.dev/denzo/spanreed.git?ref=master";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      spanreed,
    }:
    let
      domain = "nixbox.tv";
    in
    {
      nixosConfigurations = {
        nixbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nixbox/configuration.nix
            ./overlays
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.denzo = import ./users/denzo/home.nix;
              home-manager.users.root = import ./users/root/home.nix;
            }
          ];
          specialArgs = { inherit domain spanreed; };
        };
      };

      devShells = import ./devshells.nix { inherit nixpkgs; };

      checks = import ./checks.nix { inherit nixpkgs self; };

      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
      };
    };
}
