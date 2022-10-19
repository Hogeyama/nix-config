{ pkgs
, compiler ? "ghc8107"
}:
let
  src = pkgs.lib.sourceByRegex ./. [
    "my-xmobar.hs"
    "my-xmobar.cabal"
    "cabal.project"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
  ];
  haskPkgs = pkgs.haskell.packages.${compiler}.override {
    overrides = haskellPackagesNew: haskellPackagesOld: {
      xmobar = haskellPackagesOld.xmobar.overrideAttrs (old: {
        configureFlags = ["-f" "all_extensions"];
      });
    };
  };
  drv = (haskPkgs.callCabal2nix "my-xmobar" src { }).overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      pkgs.dropbox
      pkgs.alsa-lib
      pkgs.apulse
      pkgs.pulseaudio
    ];
  });
in
drv
