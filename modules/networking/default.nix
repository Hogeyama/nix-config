{ pkgs, ... }:
{
  networking = {
    # Enables wireless support via wpa_supplicant.
    # TODO
    wireless = {
      enable = false;
    };
    networkmanager = {
      enable = true;
    };
    useDHCP = pkgs.lib.mkForce true;
    firewall = {
      allowedUDPPorts = [ 30000 ];
    };
  };
}
