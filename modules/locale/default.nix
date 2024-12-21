{ pkgs, ... }:
{
  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
    };
  };

  environment = {
    sessionVariables = {
      GTK_IM_MODULE_FILE = "/run/current-system/sw/etc/gtk-3.0/immodules.cache";
    };
  };
}
