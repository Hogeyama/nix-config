{ ... }:
{
  services.xserver = {
    enable = true;
    xkb.layout = "jp";
    windowManager.xmonad.enable = true;
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  # Remenber display layout
  services.autorandr.enable = true;
}
