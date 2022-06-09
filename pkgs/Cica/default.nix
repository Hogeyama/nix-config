{ fetchzip, unzip }:
let
  pname = "Cica";
  version = "5.0.3";
in
fetchzip {
  name = "${pname}-${version}";
  stripRoot = false;
  url = "https://github.com/miiton/Cica/releases/download/v${version}/Cica_v${version}.zip";
  sha256 = "sha256-DtH9EoAiilc05bJ34DZ4PA8pVgrH45jBESCT/gseOrM=";
  postFetch = ''
    install -m 444 -D -t $out/share/fonts/${pname} $out/*.ttf
  '';
}
