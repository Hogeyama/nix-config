{ pkgs, ... }:
{
  sound.enable = true;
  hardware.bluetooth.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
    support32Bit = true;
    extraConfig = ''
      load-module module-switch-on-connect
      load-module module-bluetooth-policy
      load-module module-bluetooth-discover
    '';
  };
  services.blueman.enable = true;
}
