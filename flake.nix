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
    
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, deploy-rs, sops-nix }: 
    let 
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
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
        };
      };

      deploy.nodes.nixbox = {
        hostname = "nixbox";
        fastConnection = true;
        profiles.system = {
          user = "root";
          sshUser = "denzo";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixbox;
        };
      };
      
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [
          pkgs.age
          pkgs.deploy-rs
          pkgs.sops
        ];
      };
  };
}
