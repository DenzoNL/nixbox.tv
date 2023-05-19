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
  };
}
