{ self, env, inputs, ... }:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${env.user.name} = ./home.nix;
  home-manager.extraSpecialArgs = { inherit self env inputs; };
  home-manager.sharedModules = [
    inputs.nix-index-database.hmModules.nix-index
  ];
}
