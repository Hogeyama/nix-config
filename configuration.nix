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
  imports = [
    <home-manager/nixos>
    ./hardware-configuration.nix
  ];

  nix = {
    package = pkgs.nixUnstable; # or versioned attributes like nix_2_4
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # networking
  networking = {
    # Define your hostname.
    hostName = env.hostName;
    # Enables wireless support via wpa_supplicant.
    # TODO
    wireless.enable = false;
    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    useDHCP = false;
    interfaces.enp0s20f0u4u3c2.useDHCP = true;
    interfaces.wlp2s0.useDHCP = true;
  };

  # Enable sound.
  sound.enable = true;
  # Enable bluetooth.
  hardware.bluetooth.enable = true;
  # No pulseaudio.
  # hardware.pulseaudio.enable = true;

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
    displayManager.lightdm.enable = true;
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
  services.autorandr = {
    enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      awscli2
      aws-sam-cli
      bat
      curl
      deno
      docker
      docker-compose
      fd
      feh
      file
      firefox
      fuse
      fzf
      git
      go
      golangci-lint
      google-cloud-sdk
      htop
      jq
      mercurial
      neovim-remote
      nodejs
      nodePackages.bash-language-server
      nodePackages.npm
      ripgrep
      rnix-lsp
      unar
      vifm
      wget
      xsel
      yq
      # unstable packages
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
      extraGroups = [ "wheel" ];
      hashedPassword = env.user.hashedPassword;
    };
  };

  home-manager.users.${env.user.name} = { config, pkgs, ... }:
    import ./home-manager/home.nix {
      inherit config pkgs unstablePkgs;
    };

  nix.trustedUsers = [ env.user.name ];
}
