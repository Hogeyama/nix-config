{ pkgs, ... }:
{
  networking = {
    # wpa_supplicant is enabled and DBus-controlled by NetworkManager
    # (networking.networkmanager sets wireless.enable since nixos-26.05).
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
