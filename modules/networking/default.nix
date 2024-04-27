{ env, ... }:
{
  networking = {
    # Define your hostname.
    hostName = env.hostName;
    # Enables wireless support via wpa_supplicant.
    # TODO
    wireless = {
      enable = false;
    };
    networkmanager = {
      enable = true;
    };
    useDHCP = false;
    interfaces.${env.interface}.useDHCP = true;
  };
}
