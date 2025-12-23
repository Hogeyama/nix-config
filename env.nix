rec {
  hostName = "nixos";

  isWsl = false;

  user = {
    name = "hogeyama";
    homeDirectory = "/home/hogeyama";
    email = "gan13027830@gmail.com";
    browser = "firefox";
    terminal = "konsole";
    xmonad-layout = "1+xmobar";
  };

  nixosModule = args@{ pkgs, config, ... }: {
    users = {
      users = {
        ${user.name} = {
          uid = 1000;
          isNormalUser = true;
          home = user.homeDirectory;
          group = user.name;
          extraGroups = [ "wheel" "networkmanager" "docker" ];
          hashedPasswordFile = config.sops.secrets.login-password.path;
          shell = pkgs.zsh;
        };
      };
      groups = {
        ${user.name} = {
          gid = 1000;
          members = [ user.name ];
        };
      };
    };
    nix.settings.trusted-users = [ user.name ];

    xdg.mime.defaultApplications = {
      "text/html" = "${user.browser}.desktop";
      "x-scheme-handler/https" = "${user.browser}.desktop";
      "x-scheme-handler/http" = "${user.browser}.desktop";
    };

    sops.secrets."login-password" = {
      sopsFile = ./secrets/common.yaml;
      neededForUsers = true;
    };
    sops.secrets."aws/hogeyama" = {
      sopsFile = ./secrets/common.yaml;
      mode = "0440";
      path = "/root/.aws/credentials";
    };
    sops.secrets."gh-auth-token" = {
      sopsFile = ./secrets/common.yaml;
    };
    sops.templates."nix-secret.conf" = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder.gh-auth-token}
      '';
      owner = user.name;
      group = user.name;
      mode = "0400";
    };
    nix.extraOptions = ''
      !include ${config.sops.templates."nix-secret.conf".path}
    '';

    programs.steam.enable = true;

    home-manager.users.${user.name} = homeManagerModule args;
  };

  homeManagerModule = { pkgs, ... }: {
    programs = {
      git = {
        settings = {
          user = {
            name = user.name;
            email = user.email;
          };
        };
      };
      waybar = {
        settings.mainBar = {
          height = 48;
          output = [ "HDMI-A-2" ];
        };
      };
    };
    services = {
      swayidle.timeouts = [
        {
          # 5分でロック
          timeout = 3000;
          command = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
        }
      ];
      kanshi.settings = [
        {
          profile = {
            name = "home";
            outputs = [
              {
                criteria = "DP-1";
                status = "enable";
                mode = "3840x2160@60";
                position = "0,0";
                scale = 1.25;
                transform = "270";
              }
              {
                criteria = "HDMI-A-2";
                status = "enable";
                mode = "3840x2160@60";
                position = "1728,912";
                scale = 1.0;
                transform = "normal";
              }
            ];
          };
        }
      ];
    };
    wayland.windowManager.hyprland = {
      # パッケージはNixOSで管理
      package = null;
      portalPackage = null;
    };

    # Hyprlandがsuspendから復帰するときにfcitx5と接続が切れてfcitx5がexit 0するらしい。
    # > Sep 06 13:13:53 nixos uwsm_Hyprland[3375]: error in client communication (pid 101812)
    # > Sep 06 13:13:53 nixos fcitx5[101812]: wl_display#1: error 0: invalid object 17
    # > Sep 06 13:13:53 nixos fcitx5[101812]: E2025-09-06 13:13:53.873618 waylandeventreader.cpp:129] Wayland connection got error: 22
    # Restart=alwaysで毎回再起動するようにしておく。
    systemd.user.services.fcitx5 = {
      Unit = {
        Description = "Fcitx5 input method daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        # わざわざ pkgs.fcitx5-with-addons.override ... を modules/locale/default.nix から公開して……
        # とかやるほどのことでもないので直パスを指定する。どうせ Debian 環境では apt で入れた fcitx5 を使うのだし。
        ExecStart = "/run/current-system/sw/bin/fcitx5 -r";
        Restart = "always";
        RestartSec = 2;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

  };
}
