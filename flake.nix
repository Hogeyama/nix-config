{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-haskell.url = "github:NixOS/nixpkgs/3fb937a1e9f4157f57011965b99fcb7f4139d9ad";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.inputs.nix-index-database.follows = "nix-index-database";
    nix-alien.inputs.flake-utils.follows = "flake-utils";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    my-fzf-wrapper.url = "github:Hogeyama/my-fzf-wrapper";
    my-fzf-wrapper.inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nixpkgs-for-haskell
    , sops-nix
    , home-manager
    , neovim-nightly-overlay
    , nix-index-database
    , nix-alien
    , my-fzf-wrapper
    , ...
    }:
    let
      system = "x86_64-linux";

      env = import ./env.nix;
      hostName = env.hostName;
      username = env.user.name;

      my-overlay = final: prev: {
        # unstable packages are available as pkgs.unstable.${package}
        unstable = nixpkgs-unstable.outputs.legacyPackages.${system};
        haskell-updates = nixpkgs-for-haskell.outputs.legacyPackages.${system};
        # my packages
        illusion = import ./pkgs/illusion { pkgs = final; };
        udev-gothic = import ./pkgs/udev-gothic { inherit (final) fetchzip; };

        my-xmobar = import ./pkgs/my-xmobar { pkgs = final.haskell-updates; };
        my-xmonad = import ./pkgs/my-xmonad { pkgs = final.haskell-updates; };
        my-fzf-wrapper = my-fzf-wrapper.outputs.packages.${system}.default;
      };

      overlays = [
        my-overlay
        neovim-nightly-overlay.overlay
        nix-alien.overlays.default
      ];
    in
    {
      # For NixOS
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (_: { _module.args = { inherit env; }; })
          (_: { nixpkgs.overlays = overlays; })
          ./modules/configuration
          ./modules/hardware-configuration
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = ./home.nix;
            home-manager.extraSpecialArgs = { inherit self env; };
            home-manager.sharedModules = [
              nix-index-database.hmModules.nix-index
            ];
          }
          sops-nix.nixosModules.sops
          env.extraConfig
        ];
      };

      # For Nix package manager only
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = self.nixosConfigurations.${hostName}.pkgs;
        modules = [
          ({ config, pkgs, ... }: import ./home.nix { inherit config pkgs self; })
          {
            home = {
              inherit username;
              homeDirectory = env.user.homeDirectory;
              stateVersion = "22.11";
            };
          }
        ];
      };

      devShells.${system}.xmonad =
        self.nixosConfigurations.${hostName}.pkgs.my-xmonad.passthru.shell;
    };
}
