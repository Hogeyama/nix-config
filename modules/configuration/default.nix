{ pkgs, ... }:
{
  system.stateVersion = "22.11";

  # Enable qmk and via
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ pkgs.via ];

  security.sudo.wheelNeedsPassword = false;
}
