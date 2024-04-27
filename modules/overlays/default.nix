{ inputs, system, ... }:
let
  overlays = [
    inputs.neovim-nightly-overlay.overlay
    inputs.nix-alien.overlays.default
    (pkgs: _: {
      unstable = inputs.nixpkgs-unstable.outputs.legacyPackages.${system};
      haskell-updates = inputs.nixpkgs-for-haskell.outputs.legacyPackages.${system};
      my-fzf-wrapper = inputs.my-fzf-wrapper.outputs.packages.${system}.default;

      illusion = import ./illusion { inherit pkgs; };
      udev-gothic = import ./udev-gothic { inherit (pkgs) fetchzip; };
      my-xmobar = import ./my-xmobar { pkgs = pkgs.haskell-updates; };
      my-xmonad = import ./my-xmonad { pkgs = pkgs.haskell-updates; };
    })
  ];
in
{ nixpkgs.overlays = overlays; }
