{ pkgs, ... }:
{
  fonts = {
    packages = [
      pkgs.udev-gothic.nerdfont
      pkgs.udev-gothic.jpdoc
      pkgs.rounded-mgenplus
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
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <!-- Illusion := (Illusion から ASCII を除いたもの), Rounded Mgen+ 1mn とする -->
          <match target="font">
            <!-- ASCII を除く -->
            <!-- https://stackoverflow.com/questions/47501411/ -->
            <test name="family" compare="contains">
              <string>Illusion</string>
            </test>
            <edit name="charset" mode="assign">
              <minus>
                <name>charset</name>
                <charset>
                  <range>
                    <int>0x0021</int>
                    <int>0x00FF</int>
                  </range>
                </charset>
              </minus>
            </edit>
          </match>
          <match>
            <!-- Rounded Mgen+ 1mn にフォールバックする -->
            <test qual="any" name="family" compare="contains">
              <string>Illusion</string>
            </test>
            <edit name="family" mode="append" binding="strong">
              <string>Rounded Mgen+ 1mn</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };
}
