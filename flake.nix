# /etc/nixos/flake.nix
{
  description = "Nixbox.tv Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    
    deploy-rs = {
      url = "github:serokell/deploy-rs";
    };

    vscode-server = { 
      url = "github:nix-community/nixos-vscode-server";
    };
  };

  outputs = { self, nixpkgs, deploy-rs, vscode-server }: 
    let 
      pkgs = nixpkgs.legacyPackages.x86_64-linux; 
    in 
    {
      nixosConfigurations = {
        nixbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nixbox/configuration.nix
            ./services/flood.nix
            ./services/grafana.nix
            ./services/lidarr.nix
            ./services/loki.nix
            ./services/plex.nix
            ./services/prometheus.nix
            ./services/promtail.nix
            ./services/radarr.nix
            ./services/rtorrent.nix
            ./services/sonarr.nix
            vscode-server.nixosModule(./services/vscode-server.nix)
          ];
        };
      };

      deploy.nodes.nixbox = {
        hostname = "nixbox";
        fastConnection = true;
        profiles.system = {
          user = "root";
          sshUser = "root";
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
