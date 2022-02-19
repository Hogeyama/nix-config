{ fetchzip, unzip }:
let
  pname = "illusion";
  version = "0.2.5";
in
fetchzip {
  name = "${pname}-${version}";
  url = "https://github.com/tomonic-x/Illusion/releases/download/v0.2.5/Illusion-0.2.5.zip";
  sha256 = "sha256-KVfasxjS+6tZLb04AFuWADYYy1PF80sgobjsmHN70FI=";
  postFetch = ''
    ${unzip}/bin/unzip $downloadedFile
    install -m 444 -D -t $out/share/fonts/${pname} webfont/*.ttf
  '';
}
