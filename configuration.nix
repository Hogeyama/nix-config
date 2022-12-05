{ config, pkgs, nixpkgs, ... }:
let
  env = import ./env.nix;
in
{
  system.stateVersion = "22.11";

  imports =
    if env.type == "nixos-virtualbox" then [
      "${nixpkgs.outPath}/nixos/modules/profiles/graphical.nix"
      "${nixpkgs.outPath}/nixos/modules/installer/cd-dvd/channel.nix"
      "${nixpkgs.outPath}/nixos/modules/virtualisation/virtualbox-image.nix"
    ] else [
      ./hardware-configuration.nix
    ];

  nix = {
    package = pkgs.unstable.nixUnstable; # or versioned attributes like nix_2_4
    settings = {
      substituters = [
        "s3://hogeyama-nix-cache?region=ap-northeast-1"
        "https://cache.iog.io"
      ];
      trusted-public-keys = [
        "hogeyama-nix-cache:rCcxGULOLr4ei6xv6vZObA7fqBKAt1Y6LZwmaN08Utc="
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      ];
      auto-optimise-store = true;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot = if env.type == "nixos-virtualbox" then { } else {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [
      "uhid"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = if env.type == "nixos-virtualbox" then { } else {
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
    extraConfig = ''
      ClientAliveInterval 30
      ClientAliveCountMax 120
    '';
  };

  # Enable sound.
  sound.enable = true;
  hardware.bluetooth.enable = true;
  hardware.pulseaudio = {
    # Sound config
    enable = true;
    package = pkgs.pulseaudioFull;
    support32Bit = true;
    extraConfig = "
        load-module module-switch-on-connect
      ";
  };
  services.blueman.enable = true;

  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
      # enabled = "fcitx5";
      # fcitx5.addons = [ pkgs.fcitx-mozc ];
    };
  };

  services.xserver = {
    enable = true;
    layout = "jp";

    displayManager =
      if env.type == "nixos"
      then { sddm.enable = true; }
      else { };
    desktopManager.plasma5.enable = true;
    windowManager = {
      xmonad = {
        enable = true;
        haskellPackages = pkgs.haskell.packages.ghc8107;
      };
    };
  };

  # Remenber display layout
  services.autorandr.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  # Enable gnupg-agent
  programs.gnupg = {
    agent.enable = true;
    agent.pinentryFlavor = "tty";
  };

  environment = {
    systemPackages = with pkgs; [
      awscli2
      aws-sam-cli
      bat
      bind
      curl
      docker
      docker-compose
      exa
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
      neovim-remote
      python3
      ripgrep
      rnix-lsp
      scrot
      textql
      unar
      vifm
      wget
      xsel
      yq
      fcitx-configtool
      # unstable packages
      unstable.deno
      unstable.nodejs
      unstable.nodePackages.bash-language-server
      unstable.nodePackages.npm
      unstable.neovim
    ];
  };

  fonts = {
    fonts = [
      pkgs.rounded-mgenplus
      pkgs.nerdfonts
      pkgs.noto-fonts-emoji
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-cjk-serif
    ];
    fontconfig = {
      #ultimate.enable = true;
      defaultFonts = {
        monospace = [
          "Rounded Mgen+ 1mn"
          "Noto Color Emoji"      # Emoji fallback
          "FiraMono Nerd Font"    # Nerd font fallback
          "Noto Sans Mono CJK JP" # Other fallback
        ];
        sansSerif = [
          "Rounded Mgen+ 1cp"
          "Noto Sans CJK JP"
        ];
        serif = [
          "Noto Serif CJK JP"
        ];
      };
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <!-- Illusion := (Illusion から ASCII を除いたもの), Rounded Mgen+ 1mn とする -->
          <match target="font">
            <!-- ASCII を除く -->
            <!-- https://stackoverflow.com/questions/47501411/ -->
            <test name="family" compare="contains">
              <string>Illusion</string>
            </test>
            <edit name="charset" mode="assign">
              <minus>
                <name>charset</name>
                <charset>
                  <range>
                    <int>0x0021</int>
                    <int>0x00FF</int>
                  </range>
                </charset>
              </minus>
            </edit>
          </match>
          <match>
            <!-- Rounded Mgen+ 1mn にフォールバックする -->
            <test qual="any" name="family" compare="contains">
              <string>Illusion</string>
            </test>
            <edit name="family" mode="append" binding="strong">
              <string>Rounded Mgen+ 1mn</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };

  users = {
    users = {
      ${env.user.name} = {
        uid = 1000;
        isNormalUser = true;
        home = "/home/${env.user.name}";
        group = env.user.name;
        extraGroups = [ "wheel" "networkmanager" "docker" ] ++
          (if env.type == "nixos-virtualbox" then [ "vboxsf" ] else [ ]);
        hashedPassword = env.user.hashedPassword;
        shell = pkgs.zsh;
      };
    };
    groups = {
      # singleton group
      ${env.user.name} = {
        gid = 1000;
        members = [ env.user.name ];
      };
    };
  };
  security.sudo.wheelNeedsPassword = false;

  services.gitolite = {
    enable = true;
    adminPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK2Apn34HBo5o00uK04Qrm5ySRzZqcYXFwTCKZllS4uZ";
  };
  services.keybase = {
    enable = true;
  };

  nix.settings.trusted-users = [ env.user.name ];
}
