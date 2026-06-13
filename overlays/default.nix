{ ... }:

{
  nixpkgs.overlays = [
    (import ./modifications.nix)
  ];
}
