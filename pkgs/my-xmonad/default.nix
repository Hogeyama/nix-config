{ pkgs }:
let
  src = pkgs.lib.sourceByRegex ./. [
    "my-xmonad.hs"
    "my-xmonad.cabal"
    "cabal.project"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
  ];
  drv = (pkgs.haskellPackages.callCabal2nix "xmonad-config" src { });
in
drv
