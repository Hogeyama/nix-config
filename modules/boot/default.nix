{ pkgs, ... }:
{
  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [
      "uhid"
      "vfio-pci"
    ];
    kernelParams = [ "intel_iommu=on" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };
}
