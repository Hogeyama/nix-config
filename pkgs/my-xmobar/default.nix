{ pkgs }:
let
  src = pkgs.lib.sourceByRegex ./. [
    "my-xmobar.hs"
    "my-xmobar.cabal"
    "cabal.project"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
  ];
  haskellPackages = pkgs.haskellPackages.override {
    overrides = haskellPackagesNew: haskellPackagesOld: {
      xmobar = haskellPackagesOld.xmobar.overrideAttrs (old: {
        configureFlags = [ "-f" "all_extensions" ];
      });
    };
  };
  drv = (haskellPackages.callCabal2nix "my-xmobar" src { }).overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      pkgs.dropbox
      pkgs.alsa-lib
      pkgs.apulse
      pkgs.pulseaudio
    ];
  });
in
drv
