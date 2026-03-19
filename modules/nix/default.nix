{ ... }:
{
  nix = {
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
      experimental-features = nix-command flakes auto-allocate-uids
    '';
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.firefox.speechSynthesisSupport = true;
}
