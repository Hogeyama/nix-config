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
    # Cap NVMe APST at PS3. On the Crucial T500 that holds /, exiting PS4 costs
    # 19.9ms after 5s idle, while PS3 costs 2.7ms and still drops to 25mW;
    # 10000 admits PS3 and excludes PS4 on that drive. Measured QD1 4K random
    # read: 0.08ms active, 2.7ms worst case, and `find /nix/store` is unchanged
    # (cold 2.4s) because a sustained walk never lets the drive idle.
    # The TEAM TM8FP6001T rejects APST configuration at any value, so this
    # setting neither helps nor hurts it.
    kernelParams = [ "intel_iommu=on" "nvme_core.default_ps_max_latency_us=10000" ];
    kernelPackages = pkgs.linuxPackages;
  };

  # Use mq-deadline I/O scheduler for NVMe to ensure fairness under heavy writes
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="mq-deadline"
  '';
}
