{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  name = "amazon-corretto-17";
  src = pkgs.fetchzip {
    # https://docs.aws.amazon.com/corretto/latest/corretto-17-ug/downloads-list.html から
    url = "https://corretto.aws/downloads/latest/amazon-corretto-17-x64-linux-jdk.tar.gz";
    sha256 = "sha256-jqwTurLWnLPMWjopJ2IZ6M7aUbsUhNFZ5sd9jFDkJoA=";
  };
  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.alsa-lib
    pkgs.xorg.libXrender
    pkgs.xorg.libXext
    pkgs.xorg.libXtst
    pkgs.xorg.libXi
  ];
  sourceRoot = "source";
  installPhase = ''
    mkdir -p $out
    cp -r . $out
    addAutoPatchelfSearchPath ./lib
  '';
}
