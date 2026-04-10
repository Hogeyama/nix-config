{ env, ... }:
{
  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    # NOTE: defaultUserはUID1000を持つ必要がありそう？
    defaultUser = env.user.name;
    startMenuLaunchers = true;
  };
}
