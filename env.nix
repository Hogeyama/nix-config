{
  # Choose one of
  # * nixos
  # * nixos-virtualbox
  # * nix-package-manager
  type = "nixos";

  # required only if type="nixos"
  hostName = "nixos";

  # required
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
      browser = "google-chrome-stable";
    };
}
