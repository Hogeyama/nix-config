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
  xmobar = (haskellPackages.callCabal2nix "my-xmobar" src { }).overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      pkgs.alsa-lib
      pkgs.apulse
      pkgs.pulseaudio
    ];
  });
  shell = pkgs.haskellPackages.shellFor {
    withHoogle = true;
    packages = _: [ xmobar ];
    buildInputs = with pkgs; [
      haskell-language-server
      cabal-install
    ];
  };
in
xmobar.overrideAttrs {
  passthru = {
    shell = shell;
  };
}
