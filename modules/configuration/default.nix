{ pkgs, ... }:
{
  system.stateVersion = "22.11";

  # Enable qmk and via
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ pkgs.via ];

  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
    };
  };

  security.sudo.wheelNeedsPassword = false;
}
