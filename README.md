
## 構築手順

```
cd /tmp
nix-shell -p neovim -p git
git clone https://github.com/Hogeyama/nix-config.git
cd ./nix-config
cp /etc/nixos/hardware-configuration.nix ./modules/hardware-configuration/default.nix
nvim env.nix
nixos-rebuild switch --use-remote-sudo --flake .
```
