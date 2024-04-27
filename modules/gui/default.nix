{ ... }:
{
  services.xserver = {
    enable = true;
    layout = "jp";

    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
    windowManager.xmonad.enable = true;
  };

  # Remenber display layout
  services.autorandr.enable = true;
}
