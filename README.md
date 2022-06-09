
## NixOS

多分こんな感じで動くはず

```
cd /tmp
nix-shell -p neovim -p git
git clone https://github.com/Hogeyama/nix-config.git
cd ./nix-config
cp /etc/nixos/hardware-configuration.nix ./
nvim env.nix
nixos-rebuild switch --flake .
```


* fcitx5, firefox, モニターなどの設定は手動でやる必要がある
```
fcitx5-config-qt
```

## Nix package manager only

```
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
nix-shell '<home-manager>' -A install
git clone https://github.com/Hogeyama/nix-config.git /path/to/some/dir
nano /path/to/some/dir/env.nix
home-manager switch --flake '/path/to/some/dir#<username_in_env_nix>'
```

