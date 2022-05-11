{ fetchzip, unzip }:
let
  pname = "Cica";
  version = "5.0.3";
in
fetchzip {
  name = "${pname}-${version}";
  url = "https://github.com/miiton/Cica/releases/download/v${version}/Cica_v${version}.zip";
  sha256 = "sha256-zYLM9ayg0b/wbJmzi6lA0JKzR+nmI+hY/DQknbz4+HA=";
  postFetch = ''
    ${unzip}/bin/unzip $downloadedFile
    install -m 444 -D -t $out/share/fonts/${pname} *.ttf
  '';
}
