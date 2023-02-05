{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    # mine
    my-fzf-wrapper.url = "github:Hogeyama/my-fzf-wrapper";
    my-fzf-wrapper.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
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
        Cica = import ./pkgs/Cica { inherit (final) fetchzip unzip; };
        amazon-corretto17 = import ./pkgs/amazon-corretto17 { pkgs = final; };
        aws2-wrap = import ./pkgs/aws2-wrap { pkgs = final; };

        my-xmobar = import ./pkgs/my-xmobar { pkgs = final; };
        my-xmonad = import ./pkgs/my-xmonad { pkgs = final; };
        my-fzf = import ./pkgs/my-fzf { pkgs = final; };
        my-fzf-wrapper = my-fzf-wrapper.defaultPackage.${system};
      };

      overlays = [
        my-overlay
        neovim-nightly-overlay.overlay
      ];
    in
    {
      # For NixOS
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # overlay
          ({ pkgs, ... }@args: { nixpkgs.overlays = overlays; })
          # system configuration
          ({ pkgs, ... }@args: import ./configuration.nix (args // { inherit nixpkgs; }))
          # home-manager configuration
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home.nix;
            home-manager.sharedModules = [
              # TODO Use NixOS module when 23.05 comes
              nix-index-database.hmModules.nix-index
            ];
          }
          # nix-alien
          ({ pkgs, ... }: {
            environment.systemPackages = with self.inputs.nix-alien.packages.${system}; [
              nix-alien
            ];
            # Optional, needed for `nix-alien-ld`
            programs.nix-ld.enable = true;
          })
        ];
      };

      # For Nix package manager only
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = builtins.getAttr system nixpkgs.outputs.legacyPackages // {
          overlays = overlays;
        };
        inherit system username;
        configuration = import ./home.nix;
        homeDirectory = "/home/${username}";
        stateVersion = "21.11";
      };
    };
}
