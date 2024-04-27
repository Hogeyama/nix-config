{ pkgs, env, ... }:
{
  system.stateVersion = "22.11";

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [
      "uhid"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
  };

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
  # gui application for
  programs.nm-applet.enable = true;
  # enable sshd
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
    extraConfig = ''
      ClientAliveInterval 30
      ClientAliveCountMax 120
    '';
  };

  # Enable qmk and via
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ pkgs.via ];

  # Enable sound.
  sound.enable = true;
  hardware.bluetooth.enable = true;
  hardware.pulseaudio = {
    # Sound config
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

  services.atd.enable = true;

  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
    };
  };

  services.xserver = {
    enable = true;
    layout = "jp";

    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
    windowManager.xmonad.enable = true;
  };

  # Remenber display layout
  services.autorandr.enable = true;

  # Enable docker/podman
  virtualisation.docker.enable = true;
  # https://nixos.wiki/wiki/Podman
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = false; # Do not create alias docker=podman
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

  # Enable gnupg-agent
  programs.gnupg = {
    agent.enable = true;
    agent.pinentryFlavor = "tty";
  };

  programs.zsh.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.package = pkgs.unstable.nix-ld-rs;

  environment = {
    systemPackages = with pkgs; [
      age
      awscli2
      aws-sam-cli
      bat
      bind
      bluedevil
      bluez
      bluez-alsa
      bluez-tools
      libsForQt5.bluez-qt
      curl
      deno
      docker
      docker-compose
      eza
      fd
      feh
      file
      firefox
      fuse
      fzf
      gcc
      git
      gnumake
      go
      gopls
      golangci-lint
      google-cloud-sdk
      gthumb
      htop
      jq
      libreoffice
      lsof
      mercurial
      moreutils
      neovim-remote
      nodejs
      nodePackages.npm
      nil
      nixpkgs-fmt
      nix-alien
      podman-compose
      python3
      ripgrep
      scrot
      sops
      ssh-to-age
      textql
      unar
      via
      vifm
      wezterm
      wget
      xsel
      xsv
      yq
    ];
    sessionVariables = {
      PATH = [
        ''''${HOME}/.local/bin''
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  services.keybase = {
    enable = true;
  };

  services.passSecretService.enable = true;

  services.flatpak.enable = true;
}
