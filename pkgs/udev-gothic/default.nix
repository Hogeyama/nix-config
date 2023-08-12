{ fetchzip }:
let
  pname = "udev-gothic";
  version = "1.3.1";
in
{
  nerdfont =
    fetchzip {
      name = "${pname}-nf-${version}";
      stripRoot = false;
      url = "https://github.com/yuru7/udev-gothic/releases/download/v${version}/UDEVGothic_NF_v${version}.zip";
      sha256 = "sha256-nPC0GC7uRvFSxqnVARAv0QkV7W0VecqmN3B8VLu0LV4=";
      postFetch = ''
        install -m 444 -D -t $out/share/fonts/${pname} $out/UDEVGothic_NF_v${version}/*.ttf
      '';
    };
  jpdoc =
    fetchzip {
      name = "${pname}-jpdoc-${version}";
      stripRoot = false;
      url = "https://github.com/yuru7/udev-gothic/releases/download/v${version}/UDEVGothic_v${version}.zip";
      sha256 = "sha256-p5FBRfkMKgTLEPBp2DNWU0wZQTDcZp0CmaLzeBjACxg=";
      postFetch = ''
        install -m 444 -D -t $out/share/fonts/${pname} $out/UDEVGothic_v${version}/UDEVGothicJPDOC-*.ttf
      '';
    };
}
