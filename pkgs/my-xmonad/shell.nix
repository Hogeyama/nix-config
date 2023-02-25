{ pkgs, compiler ? "ghc924" }:
pkgs.haskell.packages.${compiler}.shellFor {
  withHoogle = true;
  packages = _: [ pkgs.my-xmonad ];
  buildInputs = with pkgs; [
    haskell.packages.${compiler}.haskell-language-server
    cabal-install
  ];
}

