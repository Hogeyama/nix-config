{
  hostName = "nixos";

  interface = "enp0s31f6";

  user =
    {
      name = "hogeyama";
      hashedPassword = "$6$0VTZ2.H/6uC/TqaV$jon2WkKJZSmKJJyHgi6QlZWkr7dQ1F0rRlXVno48hxkco5ofY.FzeNnj6qBcDBjDjaK0qbxRz2sjR8OEF2mis/";
      home = {
        username = "hogeyama";
        homeDirectory = "/home/hogeyama";
      };
      git = {
        userName = "Hogeyama";
        userEmail = "gan13027830@gmail.com";
      };
      browser = "firefox";
      terminal = "konsole";
    };

  extraConfig = { ... }: {
    programs.steam.enable = true;
    sops.secrets."aws/hogeyama" = {
      sopsFile = ./secrets/common.yaml;
      mode = "0440";
      path = "/root/.aws/credentials";
    };
  };
}
