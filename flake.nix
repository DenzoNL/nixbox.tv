# /etc/nixos/flake.nix
{
  description = "Nixbox.tv Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    vscode-server = { 
      url = "github:nix-community/nixos-vscode-server";
    };
  };

  outputs = { self, nixpkgs, vscode-server }: {
    nixosConfigurations = {
      nixbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./services/plex.nix
          ./services/sonarr.nix
          vscode-server.nixosModule
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };
    };
  };
}
