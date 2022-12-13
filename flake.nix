{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # nightly neovim
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    # mine
    my-fzf-wrapper.url = "github:Hogeyama/my-fzf-wrapper";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, my-fzf-wrapper, neovim-nightly-overlay, ... }:
    let
      system = "x86_64-linux";

      env = import ./env.nix;
      hostName = env.hostName;
      username = env.user.name;

      my-overlay = final: prev: {
        # unstable packages are available as pkgs.unstable.${package}
        unstable = builtins.getAttr system nixpkgs-unstable.outputs.legacyPackages;
        # my packages
        illusion = import ./pkgs/illusion { inherit (final) fetchzip unzip; };
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
          }
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
