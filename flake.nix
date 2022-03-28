{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
      env = import ./env.nix;
      overlay = final: prev: {
        # unstable packages are available as pkgs.unstable.${package}
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        # illusion font
        illusion = import ./pkgs/illusion { inherit (prev) fetchzip unzip; };
      };
    in
    {
      nixosConfigurations.${env.hostName} = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          # overlay
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay ]; })
          # system configuration
          ./configuration.nix
          # home-manager configuration
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${env.user.name} = import ./home-manager/home.nix;
          }
        ];
      };
    };
}
