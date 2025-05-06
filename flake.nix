{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-haskell.url = "github:NixOS/nixpkgs/3fb937a1e9f4157f57011965b99fcb7f4139d9ad";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
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

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.inputs.flake-utils.follows = "flake-utils";

    my-fzf-wrapper.url = "github:Hogeyama/my-fzf-wrapper";
    my-fzf-wrapper.inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , sops-nix
    , home-manager
    , nixos-wsl
    , determinate
    , ...
    }:
    let
      system = "x86_64-linux";

      env = import ./env.nix;
      hostName = env.hostName;
      username = env.user.name;
    in
    {
      # For NixOS
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixos-wsl.nixosModules.wsl
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          determinate.nixosModules.default
        ]
        ++ [
          (_: { _module.args = { inherit self inputs system env; }; })
          ./modules/overlays
          ./modules/nix
          ./modules/locale
          ./modules/syslog
          ./modules/programs
          ./modules/fonts
          ./modules/keyboard
          ./modules/configuration
          ./modules/home
          ./modules/qemu
        ]
        ++ (if env.isWsl then [
          ./modules/wsl
        ] else [
          ./modules/boot
          ./modules/gui
          ./modules/networking
          ./modules/sound
          ./modules/hardware-configuration
        ])
        ++ [
          env.nixosModule
        ];
      };

      # For Nix package manager only
      # FIXME: modules/homeに移動
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = self.nixosConfigurations.${hostName}.pkgs;
        modules = [
          ({ config, pkgs, ... }: import ./modules/home/home.nix { inherit inputs env config pkgs self; })
          inputs.nix-index-database.hmModules.nix-index
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
