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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
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
          specialArgs = { inherit domain; };
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
