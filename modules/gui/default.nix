{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = builtins.concatStringsSep " " [
        "${pkgs.greetd.tuigreet}/bin/tuigreet"
        "--time"
        "--remember"
        "--remember-session"
        "--sessions /run/current-system/sw/share/wayland-sessions"
      ];
      user = "greeter";
    };
  };

  # pam_gnupgは使わない。前提の「ログインパスワードとGPG鍵のパスフレーズが同一」を
  # 満たしていない(ログイン側が短い)ため温めが成立せず、かつ副作用が大きかった:
  # pam_gnupgがsession段階でgpg-agentのsocketを叩くと、uwsmがWAYLAND_DISPLAYを
  # systemd user managerへ投入するより約0.8秒早くgpg-agentが起動してしまう。
  # 既に起動済みのserviceには後からの環境が反映されないので、gpg-agentが生む
  # pinentryは恒久的にWAYLAND_DISPLAYを持てず、pinentry-qtの初回表示が23秒かかっていた。
  # パスフレーズはgpg-agentのcache-ttl(100h)に任せる。

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
}
