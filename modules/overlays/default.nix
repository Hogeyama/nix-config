{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  overlays = [
    inputs.nix-alien.overlays.default
    (pkgs: _: {
      unstable = inputs.nixpkgs-unstable.outputs.legacyPackages.${system};
      haskell-updates = inputs.nixpkgs-for-haskell.outputs.legacyPackages.${system};
      my-fzf-wrapper = inputs.my-fzf-wrapper.outputs.packages.${system}.default;
      vscode-insiders-nightly = inputs.vscode-insiders-nightly.packages.${system}.vscode-insider;

      illusion = import ./illusion { inherit pkgs; };
      udev-gothic = import ./udev-gothic { inherit (pkgs) fetchzip; };
      my-xmobar = import ./my-xmobar { pkgs = pkgs.haskell-updates; };
      my-xmonad = import ./my-xmonad { pkgs = pkgs.haskell-updates; };
    })
  ];
in
{ nixpkgs.overlays = overlays; }
