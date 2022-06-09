{ fetchzip, unzip }:
let
  pname = "illusion";
  version = "0.2.5";
in
fetchzip {
  name = "${pname}-${version}";
  stripRoot = false;
  url = "https://github.com/tomonic-x/Illusion/releases/download/v0.2.5/Illusion-0.2.5.zip";
  sha256 = "sha256-BrfDqcHUIl1vYrU8+krsdiNuJJoqOAxBl+VofQr/690=";
  postFetch = ''
    install -m 444 -D -t $out/share/fonts/${pname} $out/webfont/*.ttf
  '';
}
