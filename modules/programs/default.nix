{ pkgs, ... }:
{
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
  };

  # gui application for
  programs.nm-applet.enable = true;

  # Enable gnupg-agent
  programs.gnupg = {
    agent.enable = true;
    agent.pinentryFlavor = "tty";
  };

  programs.nix-ld = {
    enable = true;
    package = pkgs.unstable.nix-ld-rs;
  };

  programs.zsh.enable = true;

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

  services.keybase.enable = true;

  services.passSecretService.enable = true;

  services.flatpak.enable = true;

  services.atd.enable = true;

  virtualisation.docker.enable = true;

  # https://nixos.wiki/wiki/Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Do not create alias docker=podman
    defaultNetwork.settings.dns_enabled = true;
  };
}
