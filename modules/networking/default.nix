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
    dhcpcd.denyInterfaces = [ "veth*" ];
    firewall = {
      allowedUDPPorts = [ 30000 ];
      trustedInterfaces = [ "docker0" ];
    };
  };
}
