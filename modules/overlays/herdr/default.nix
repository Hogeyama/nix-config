{ lib, fetchurl, stdenv, stdenvNoCC, autoPatchelfHook }:
# nixpkgsにもある(pkgs/by-name/he/herdr)が、ロック中のnixpkgsにはまだ入っていない。
# ソースビルドはzig 0.16を要するので、公式のリリースバイナリをそのまま使う。
stdenvNoCC.mkDerivation rec {
  pname = "herdr";
  version = "0.9.3";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-x86_64";
    # GitHub releaseのassetに載っているdigest
    sha256 = "18a8dc65f1c2fa485884344356dea1cfd911c6f06cf46fa78e193f4087f4dba7";
  };

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr";
  };
}
