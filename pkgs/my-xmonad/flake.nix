{
  description = "my xmonad configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils/master";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" ];
      compiler = "ghc8107";
      outputs-overlay = pkgs: prev: {
        my-xmonad = (import ./. { inherit pkgs compiler; });
        my-env = (import ./shell.nix { inherit pkgs compiler; });
      };
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ outputs-overlay ];
        };
      in {
        defaultPackage = pkgs.my-xmonad;
        devShell = pkgs.my-env;
      });
}
