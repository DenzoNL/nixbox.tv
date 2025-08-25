{ ... }:

{
  nixpkgs.overlays = [
    # Modifications to existing packages
    (import ./modifications.nix)
    
    # Custom packages (additions)
    (import ./additions.nix)
  ];
}