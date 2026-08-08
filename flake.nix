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
    # can't reach it. Follows our nixpkgs (both nixos-unstable).
    spanreed = {
      url = "git+https://switchbyte.dev/denzo/spanreed.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Temporary: nixpkgs PR #547607 (romm: init; nixos/romm: init), used only
    # for the romm module + package until it lands in nixos-unstable.
    nixpkgs-romm = {
      url = "github:NixOS/nixpkgs?ref=pull/547607/head";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-romm,
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
          specialArgs = { inherit domain nixpkgs-romm spanreed; };
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
