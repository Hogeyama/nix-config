{ pkgs, env, ... }:

{
  # https://www.reddit.com/r/NixOS/comments/177wcyi/comment/k4vok4n/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1
  programs.dconf.enable = true;
  programs.virt-manager.enable = true;

  users.users.${env.user.name}.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    libvirt
    virt-manager
    virt-viewer
    # spice
    # spice-gtk
    # spice-protocol
    win-virtio
    # win-spice
    quickemu
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    # spiceUSBRedirection.enable = true;
  };
  # services.spice-vdagentd.enable = true;
}
