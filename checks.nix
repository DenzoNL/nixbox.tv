# `nix flake check` gates: formatting, lints, dead code. Evaluating the
# nixosConfiguration itself is part of `nix flake check` by default.
{ nixpkgs, self }:
let
  mkChecks =
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      format = pkgs.runCommand "check-format" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
        find ${self} -name '*.nix' -exec nixfmt --check {} +
        touch $out
      '';

      statix = pkgs.runCommand "check-statix" { nativeBuildInputs = [ pkgs.statix ]; } ''
        cd ${self} && statix check .
        touch $out
      '';

      deadnix = pkgs.runCommand "check-deadnix" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
        deadnix --fail ${self}
        touch $out
      '';
    };
in
{
  x86_64-linux = mkChecks "x86_64-linux";
  aarch64-darwin = mkChecks "aarch64-darwin";
}
