{ pkgs, compiler ? "ghc924" }:
let
  src = pkgs.lib.sourceByRegex ./. [
    "my-xmonad.hs"
    "my-xmonad.cabal"
    "cabal.project"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
  ];
  # xmonad 0.17.0
  haskPkgs = pkgs.haskell.packages.${compiler};
  drv = (haskPkgs.callCabal2nix "xmonad-config" src { });
in
drv
