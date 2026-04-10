{ fetchurl, stdenvNoCC, autoPatchelfHook }:
stdenvNoCC.mkDerivation rec {
  pname = "mo";
  version = "1.1.0";

  src = fetchurl {
    url = "https://github.com/k1LoW/mo/releases/download/v${version}/mo_v${version}_linux_amd64.tar.gz";
    sha256 = "243e3a8fa08dfec69d8bcb8260a4f7e14d3b68d1bef01e18d8ca370121555c40";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    install -Dm755 mo $out/bin/mo
  '';

  meta = {
    description = "Markdown viewer that opens .md files in a browser";
    homepage = "https://github.com/k1LoW/mo";
  };
}
