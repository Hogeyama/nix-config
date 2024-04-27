rec {
  hostName = "nixos";

  user = {
    name = "hogeyama";
    homeDirectory = "/home/hogeyama";
    email = "gan13027830@gmail.com";
    browser = "firefox";
    terminal = "konsole";
  };

  nixosModule = { pkgs, config, ... }: {
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

    home-manager.users.${user.name}.programs.git = {
      userName = user.name;
      userEmail = user.email;
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
  };
}
