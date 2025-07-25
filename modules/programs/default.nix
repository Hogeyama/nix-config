{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      age
      awscli2
      aws-sam-cli
      bat
      bind
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
      imagemagick
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
      postgresql
      pstree
      python3
      ripgrep
      scrot
      sops
      ssh-to-age
      textql
      unar
      unzip
      via
      vifm
      wezterm
      wget
      xsel
      yq
    ];
  };

  # gui application for
  programs.nm-applet.enable = true;

  # Enable gnupg-agent
  programs.gnupg = {
    agent.enable = true;
    agent.pinentryPackage = pkgs.pinentry-tty;
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

  services.atd.enable = true;

  virtualisation.docker.enable = true;

  # https://nixos.wiki/wiki/Podman
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = false; # Do not create alias docker=podman
  #   defaultNetwork.settings.dns_enabled = true;
  # };
}
