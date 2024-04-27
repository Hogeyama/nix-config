{ pkgs, ... }:
{
  fonts = {
    packages = [
      pkgs.udev-gothic.nerdfont
      pkgs.udev-gothic.jpdoc
      pkgs.rounded-mgenplus
      (pkgs.nerdfonts.override { fonts = [ "Hack" ]; })
      pkgs.noto-fonts-emoji
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-cjk-serif
    ];
    fontconfig = {
      #ultimate.enable = true;
      defaultFonts = {
        monospace = [
          "Illusion N"
          "Rounded Mgen+ 1mn"
          "Noto Color Emoji" # Emoji fallback
          "Hack Nerd Font" # Nerd font fallback
          "Noto Sans Mono CJK JP" # Other fallback
        ];
        sansSerif = [
          "Rounded Mgen+ 1cp"
          "Noto Sans CJK JP"
        ];
        serif = [
          "Noto Serif CJK JP"
        ];
      };
    };
  };
}
