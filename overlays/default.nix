{ ... }:

{
  nixpkgs.overlays = [
    (import ./rtorrent.nix)
  ];
}
