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

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
}
