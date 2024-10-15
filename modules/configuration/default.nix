{ ... }:
{
  system.stateVersion = "22.11";
  security.sudo.wheelNeedsPassword = false;
  services.fstrim.enable = true;
}
