{ config, pkgs, ... }:
let
  env = import ./env.nix;
  unstablePkgs = import <nixos-unstable> { };
  myPkgs = {
    illusion = import ./pkgs/illusion {
      inherit (pkgs) fetchzip unzip;
    };
  };
in
{
  imports =
    if env.type == "nixos-virtualbox" then [
      <home-manager/nixos>
      <nixpkgs/nixos/modules/profiles/graphical.nix>
      <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
      <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
    ] else [
      <home-manager/nixos>
      ./hardware-configuration.nix
    ];

  nix = {
    package = pkgs.nixUnstable; # or versioned attributes like nix_2_4
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
    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    useDHCP = false;
    interfaces.wlp2s0.useDHCP = true;
  };
  # gui application for
  programs.nm-applet.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.bluetooth.enable = true;
  hardware.pulseaudio = {
    # Sound config
    enable = true;
    package = pkgs.pulseaudioFull;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
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
      enabled = "fcitx5";
      fcitx5.addons = [ pkgs.fcitx5-mozc ];
    };
  };

  services.xserver = {
    enable = true;
    layout = "jp";
    displayManager =
      if env.type == "nixos-virtualbox"
      then { }
      else { sddm.enable = true; };
    desktopManager.plasma5.enable = true;
    windowManager = {
      xmonad = {
        enable = true;
        haskellPackages = pkgs.haskell.packages.ghc8107.override {
          overrides = haskellPackagesNew: haskellPackagesOld: {
            xmonad = haskellPackagesOld.xmonad_0_17_0;
            xmonad-contrib = haskellPackagesOld.xmonad-contrib_0_17_0;
          };
        };
      };
    };
  };

  # Remenber display layout
  services.autorandr.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;
  services.syslog-ng.enable = true;

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
      ripgrep
      rnix-lsp
      scrot
      textql
      unar
      vifm
      wget
      xsel
      yq
      # unstable packages
      unstablePkgs.deno
      unstablePkgs.nodejs
      unstablePkgs.nodePackages.bash-language-server
      unstablePkgs.nodePackages.npm
      unstablePkgs.neovim
    ];
  };

  fonts = {
    fonts = [
      pkgs.ipafont
      pkgs.dejavu_fonts
      pkgs.rounded-mgenplus
      myPkgs.illusion
    ];
    fontconfig = {
      #ultimate.enable = true;
      defaultFonts = {
        monospace = [
          "Illusion N"
          "Rounded Mgen+ 1mn"
          "DejaVu Sans Mono"
          "IPAGothic"
        ];
        sansSerif = [
          "Rounded Mgen+ 1cp"
          "DejaVu Sans"
          "IPAGothic"
        ];
        serif = [
          "DejaVu Serif"
          "IPAMincho"
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

  users.users = {
    ${env.user.name} = {
      isNormalUser = true;
      home = "/home/${env.user.name}";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "networkmanager" "docker" ] ++
        (if env.type == "nixos-virtualbox" then [ "vboxsf" ] else [ ]);
      hashedPassword = env.user.hashedPassword;
    };
  };
  security.sudo.wheelNeedsPassword = false;

  home-manager.users.${env.user.name} = { config, pkgs, ... }:
    import ./home-manager/home.nix {
      inherit config pkgs unstablePkgs;
    };

  nix.trustedUsers = [ env.user.name ];
}
