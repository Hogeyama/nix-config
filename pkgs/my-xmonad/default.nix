{ pkgs, compiler ? "ghc8107" }:
let
  src = pkgs.lib.sourceByRegex ./. [
    "my-xmonad.hs"
    "my-xmonad.cabal"
    "cabal.project"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
  ];
  haskPkgs = pkgs.haskell.packages.${compiler}.override {
    overrides = haskellPackagesNew: haskellPackagesOld: {
      xmonad = haskellPackagesOld.xmonad_0_17_0;
      xmonad-contrib = haskellPackagesOld.xmonad-contrib_0_17_0;
    };
  };
  drv = (haskPkgs.callCabal2nix "xmonad-config" src { });
in
drv
