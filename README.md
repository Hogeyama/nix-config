
## NixOS

多分こんな感じで動くはず

```
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell -p git
mv /etc/nixos /etc/nixos.bak
git clone https://github.com/Hogeyama/nixos-config.git /etc/nixos
cp /etx/nixos.bak/hardware-configuration.nix /etc/nixos/hardware-configuration.nix
cp /etc/nixos/env-example.nix /etc/nixos/env.nix
nano /etc/nixos/env.nix
nixos-rebuild switch
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

