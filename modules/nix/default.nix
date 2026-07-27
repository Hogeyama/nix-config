{ ... }:
{
  nix = {
    settings = {
      substituters = [
        "s3://hogeyama-nix-cache?region=ap-northeast-1"
      ];
      trusted-public-keys = [
        "hogeyama-nix-cache:23HHz6x8J47bSCM0z6kZ++3x1ZXVPorsv3AJg1yqwAQ="
      ];
      auto-optimise-store = false;
    };
    extraOptions = ''
      experimental-features = nix-command flakes auto-allocate-uids
    '';
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.firefox.speechSynthesisSupport = true;
}
