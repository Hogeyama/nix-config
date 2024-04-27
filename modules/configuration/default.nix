{ pkgs, ... }:
{
  system.stateVersion = "22.11";

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

  services.atd.enable = true;

  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
    };
  };

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
