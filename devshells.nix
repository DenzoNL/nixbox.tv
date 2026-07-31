{ nixpkgs }:
let
  mkDevShell =
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      deploy = pkgs.writeShellScriptBin "deploy" ''
        exec ${pkgs.nh}/bin/nh os switch . -H nixbox --target-host nixbox.tv --build-host nixbox.tv
      '';
    in
    pkgs.mkShell {
      packages = with pkgs; [
        age
        deadnix
        deploy
        nh
        nixfmt
        nixos-rebuild
        sops
        statix
      ];
      shellHook = ''
        echo "Dev shell ready. Run 'deploy' to deploy to nixbox.tv."
      '';
    };
in
{
  x86_64-linux.default = mkDevShell "x86_64-linux";
  aarch64-darwin.default = mkDevShell "aarch64-darwin";
}
