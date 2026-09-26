{ config, env, ... }:
{
  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    # NOTE: defaultUserはUID1000を持つ必要がありそう？
    defaultUser = env.user.name;
    startMenuLaunchers = true;
  };
  # WSLがresolv.confを生成するのでresolvconfは無効化する
  networking.resolvconf.enable = !config.wsl.wslConf.network.generateResolvConf;
}
