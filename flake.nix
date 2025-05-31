# /etc/nixos/flake.nix
{
  description = "Nixbox.tv Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-25.05";
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

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, sops-nix }: 
    let 
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      customPkgs = import ./packages { inherit pkgs; };
      pkgsStable = nixpkgs-stable.legacyPackages.x86_64-linux;
      domain = "nixbox.tv";
    in 
    {      
      nixosConfigurations = {
        nixbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nixbox/configuration.nix
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.denzo = import ./users/denzo/home.nix;
              home-manager.users.root = import ./users/root/home.nix;

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
          specialArgs = { inherit pkgsStable customPkgs domain; };
        };
        bifrost = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         modules = [
           ./hosts/bifrost/configuration.nix
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

      devShells = {
        x86_64-linux.default = pkgs.mkShell {
          packages = with pkgs; [
            age
            nixos-rebuild
            sops
          ];
        };

        aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
          packages = with nixpkgs.legacyPackages.aarch64-darwin; [
            age
            nixos-rebuild
            sops
          ];
        };
      };
  };
}
