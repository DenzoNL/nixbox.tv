{ pkgs }:

{
  cs2mqtt = pkgs.callPackage ./cs2mqtt { };
  ut2004-server = pkgs.callPackage ./ut2004-server { };
}