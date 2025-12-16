{ pkgs, env, ... }:
{
  services.xserver = {
    enable = true;
    xkb.layout = "jp";
    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  # Remember display layout
  services.autorandr.enable = true;

  services.displayManager.defaultSession = "hyprland-uwsm";

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
}
