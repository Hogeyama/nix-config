rec {
  hostName = "nixos";

  interface = "enp0s31f6";

  user = {
    name = "hogeyama";
    homeDirectory = "/home/hogeyama";
    email = "gan13027830@gmail.com";
    browser = "firefox";
    terminal = "konsole";

    hashedPassword = "$6$0VTZ2.H/6uC/TqaV$jon2WkKJZSmKJJyHgi6QlZWkr7dQ1F0rRlXVno48hxkco5ofY.FzeNnj6qBcDBjDjaK0qbxRz2sjR8OEF2mis/";
  };

  extraConfig = { pkgs, ... }: {
    users = {
      users = {
        ${user.name} = {
          uid = 1000;
          isNormalUser = true;
          home = user.homeDirectory;
          group = user.name;
          extraGroups = [ "wheel" "networkmanager" "docker" ];
          hashedPassword = user.hashedPassword;
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

    programs.steam.enable = true;
    sops.secrets."aws/hogeyama" = {
      sopsFile = ./secrets/common.yaml;
      mode = "0440";
      path = "/root/.aws/credentials";
    };
  };
}
