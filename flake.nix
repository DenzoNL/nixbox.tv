# /etc/nixos/flake.nix
{
  description = "Nixbox.tv Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, deploy-rs }: 
    let 
      pkgs = nixpkgs.legacyPackages.x86_64-linux; 
    in 
    {
      nixosConfigurations = {
        nixbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nixbox/configuration.nix
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
          pkgs.deploy-rs
        ];
      };
  };
}
