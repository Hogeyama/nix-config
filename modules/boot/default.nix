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
    kernelPackages = pkgs.linuxPackages;
  };

  # Use mq-deadline I/O scheduler for NVMe to ensure fairness under heavy writes
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="mq-deadline"
  '';
}
