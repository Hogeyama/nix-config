{ pkgs, compiler ? "ghc924" }:
pkgs.haskell.packages.${compiler}.shellFor {
  withHoogle = true;
  packages = _: [ pkgs.my-package ];
  buildInputs = with pkgs; [
    haskell.packages.${compiler}.haskell-language-server
    cabal-install
  ];
}

