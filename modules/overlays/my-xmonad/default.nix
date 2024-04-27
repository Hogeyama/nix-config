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
  xmonad = pkgs.haskellPackages.callCabal2nix "xmonad-config" src { };
  shell = pkgs.haskellPackages.shellFor {
    withHoogle = true;
    packages = _: [ xmonad ];
    buildInputs = with pkgs; [
      haskell-language-server
      cabal-install
    ];
  };
in
xmonad.overrideAttrs {
  passthru = {
    shell = shell;
  };
}
