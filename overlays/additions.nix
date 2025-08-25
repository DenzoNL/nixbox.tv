# Additions overlay - new packages not in nixpkgs
final: prev: {

  # Add all custom packages
  cs2mqtt = final.callPackage ../packages/cs2mqtt { };

}