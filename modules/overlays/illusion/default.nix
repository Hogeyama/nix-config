{ pkgs }:
let
  pname = "illusion";
  version = "0.2.5";
in
pkgs.fetchzip {
  name = "${pname}-${version}-nonascii";
  stripRoot = false;
  url = "https://github.com/tomonic-x/Illusion/releases/download/v0.2.5/Illusion-0.2.5.zip";
  sha256 = "sha256-bHzy2pDcQAvwSUW7hCkDjpcGN+QMEBLHUV0nO2a2pzs=";
  postFetch = ''
    mkdir -p $out/share/fonts/${pname}
    # Ascii範囲を除外
    for f in $out/webfont/Illusion-N-*.ttf; do
      ${pkgs.python310Packages.fonttools.out}/bin/pyftsubset \
        "$f" \
        --unicodes="U+007F-FFFF" \
        --layout-features='*' \
        --glyph-names \
        --symbol-cmap \
        --legacy-cmap \
        --notdef-glyph \
        --notdef-outline \
        --recommended-glyphs \
        --name-IDs='*' \
        --name-legacy \
        --name-languages='*' \
        --output-file="$out/share/fonts/${pname}/$(basename "$f")"
    done
  '';
}
