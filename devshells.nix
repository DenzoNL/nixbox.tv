{ nixpkgs }:
let
  mkDevShell = system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      # `deploy [host]` builds and activates the configuration on the given
      # host (defaults to nixbox) via nh. Shipped as a real executable so it
      # works in any shell, including under direnv (where shellHook functions
      # are not exported to the interactive shell).
      # nh prompts locally for the remote sudo password and feeds it over SSH.
      deploy = pkgs.writeShellScriptBin "deploy" ''
        host="''${1:-nixbox}"
        exec ${pkgs.nh}/bin/nh os switch . -H "$host" --target-host "$host" --build-host "$host"
      '';
    in
    pkgs.mkShell {
      packages = with pkgs; [
        age
        deploy
        nh
        nixos-rebuild
        sops
      ];
      shellHook = ''
        echo "Dev shell ready. Run 'deploy [host]' to deploy (default: nixbox)."
      '';
    };
in
{
  x86_64-linux.default = mkDevShell "x86_64-linux";
  aarch64-darwin.default = mkDevShell "aarch64-darwin";
}
