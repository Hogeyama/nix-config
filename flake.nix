{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.inputs.nix-index-database.follows = "nix-index-database";
    nix-alien.inputs.flake-compat.follows = "flake-compat";
    nix-alien.inputs.flake-utils.follows = "flake-utils";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.flake-compat.follows = "flake-compat";

    my-fzf-wrapper.url = "github:Hogeyama/my-fzf-wrapper";
    my-fzf-wrapper.inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
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
        unstable = builtins.getAttr system nixpkgs-unstable.outputs.legacyPackages;
        # my packages
        illusion = import ./pkgs/illusion { pkgs = final; };
        udev-gothic = import ./pkgs/udev-gothic { inherit (final) fetchzip; };

        my-xmobar = import ./pkgs/my-xmobar { pkgs = final; };
        my-xmonad = import ./pkgs/my-xmonad { pkgs = final; };
        my-fzf-wrapper = my-fzf-wrapper.outputs.packages.${system}.default;
      };

      overlays = [
        my-overlay
        neovim-nightly-overlay.overlay
        nix-alien.overlays.default
      ];

      pkgs = import nixpkgs { inherit system overlays; };
    in
    {
      # For NixOS
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # overlay
          (_: { nixpkgs.overlays = overlays; })
          # system configuration
          ({ config, pkgs, ... }: import ./configuration.nix ({
            inherit config pkgs nixpkgs;
          }))
          # home-manager configuration
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} =
              { config, pkgs, ... }: import ./home.nix { inherit config pkgs self; };
            home-manager.sharedModules = [
              nix-index-database.hmModules.nix-index
            ];
          }
          # sops-nix
          sops-nix.nixosModules.sops
          # env-unique config
          env.extraConfig
        ];
      };

      # For Nix package manager only
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ config, pkgs, ... }: import ./home.nix { inherit config pkgs self; })
          {
            home = {
              inherit username;
              homeDirectory = "/home/${username}";
              stateVersion = "22.11";
            };
          }
        ];
      };

      devShells.${system}.xmonad = import ./pkgs/my-xmonad/shell.nix { inherit pkgs; };
    };
}
