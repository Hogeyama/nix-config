{ pkgs, ... }:
let
  env = import ./env.nix;
in
{
  system.stateVersion = "22.11";

  nix = {
    package = pkgs.nixVersions.nix_2_19;
    settings = {
      substituters = [
        "https://cache.iog.io"
        "s3://hogeyama-nix-cache?region=ap-northeast-1"
      ];
      trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "hogeyama-nix-cache:23HHz6x8J47bSCM0z6kZ++3x1ZXVPorsv3AJg1yqwAQ="
      ];
      auto-optimise-store = false;
    };
    extraOptions = ''
      experimental-features = nix-command flakes auto-allocate-uids configurable-impure-env
    '';
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.firefox.speechSynthesisSupport = true;

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

  xdg.mime.defaultApplications = {
    "text/html" = "${env.user.browser}.desktop";
    "x-scheme-handler/https" = "${env.user.browser}.desktop";
    "x-scheme-handler/http" = "${env.user.browser}.desktop";
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

  fonts = {
    packages = [
      pkgs.udev-gothic.nerdfont
      pkgs.udev-gothic.jpdoc
      pkgs.rounded-mgenplus
      (pkgs.nerdfonts.override { fonts = [ "Hack" ]; })
      pkgs.noto-fonts-emoji
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-cjk-serif
    ];
    fontconfig = {
      #ultimate.enable = true;
      defaultFonts = {
        monospace = [
          "Illusion N"
          "Rounded Mgen+ 1mn"
          "Noto Color Emoji" # Emoji fallback
          "Hack Nerd Font" # Nerd font fallback
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
        extraGroups = [ "wheel" "networkmanager" "docker" ];
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
  services.passSecretService.enable = true;

  services.flatpak.enable = true;

  nix.settings.trusted-users = [ env.user.name ];
}
