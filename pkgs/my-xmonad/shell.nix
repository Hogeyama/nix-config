{ pkgs }:
pkgs.haskellPackages.shellFor {
  withHoogle = true;
  packages = _: [ (import ./. { inherit pkgs; }) ];
  buildInputs = with pkgs; [
    haskell-language-server
    cabal-install
  ];
}
