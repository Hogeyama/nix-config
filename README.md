
## NixOS

多分こんな感じで動くはず

```
git clone https://github.com/Hogeyama/nixos-config.git
cd ./nixos-config
cp /etx/nixos/hardware-configuration.nix ./
nano env.nix
nixos-rebuild switch --flake .
```

* konsole, fcitx5, firefox, モニターなどの設定は手動でやる必要がある
  * 加えてモニターの設定後は `autorandr --save default` する

## Nix package manager only

```
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
nix-shell '<home-manager>' -A install
git clone https://github.com/Hogeyama/nixos-config.git /path/to/some/dir
nano /path/to/some/dir/env.nix
home-manager switch --flake '/path/to/some/dir#<username_in_env_nix>'
```

