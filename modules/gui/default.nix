{ pkgs, env, ... }:
{
  services.xserver = {
    enable = true;
    xkb.layout = "jp";
    windowManager.session = [
      {
        name = "xmonad";
        start =
          let
            xmonad = pkgs.symlinkJoin {
              name = "xmonad";
              paths = [ pkgs.my-xmonad ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/xmonad-x86_64-linux \
                  --set BROWSER  ${env.user.browser} \
                  --set TERMINAL ${env.user.terminal} \
                  --set XMONAD_LAYOUT ${env.user.xmonad-layout}
              '';
            };
          in
          ''
            systemd-cat -t xmonad -- ${xmonad}/bin/xmonad-x86_64-linux &
            waitPID=$!
          '';
      }
    ];
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

  # Remenber display layout
  services.autorandr.enable = true;

  services.displayManager.defaultSession = "xfce+xmonad";
}
