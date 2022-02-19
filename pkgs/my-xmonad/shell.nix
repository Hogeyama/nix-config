{ pkgs, compiler }:
pkgs.haskell.packages.${compiler}.shellFor {
  withHoogle = true;
  packages = _: [ pkgs.my-xmonad ];
  buildInputs = with pkgs; [
    (haskell-language-server.override {
      supportedGhcVersions = [
        (pkgs.lib.substring 3 (pkgs.lib.stringLength compiler) compiler)
      ];
    })
    haskellPackages.fourmolu
    cabal-install
    nixfmt
    cacert
  ];
}

