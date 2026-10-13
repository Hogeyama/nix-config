{ fetchurl, stdenvNoCC, autoPatchelfHook }:
stdenvNoCC.mkDerivation rec {
  pname = "mo";
  version = "1.6.8";

  src = fetchurl {
    url = "https://github.com/k1LoW/mo/releases/download/v${version}/mo_v${version}_linux_amd64.tar.gz";
    sha256 = "sha256-M5cnCYNoMlef3kWtuFEr0V9ETcSE/5iMAzFXnTXxFbg=";
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
