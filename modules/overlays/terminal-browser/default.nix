{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, callPackage
}:
# 公式はcurl | bashで~/.local/share/terminal-browser/appに展開する。
# 中身はElectron(pixel)とそれをnodeモードで動かすCLIで、bin/terminal-browserの
# shimは自身の位置からルートを解決するのでstoreに置いたまま動く。
# `terminal-browser upgrade`はstoreを書き換えられないので使わない。
let
  electron = callPackage ../pixel-electron.nix { };
in
stdenvNoCC.mkDerivation rec {
  pname = "terminal-browser";
  version = "0.13.4";

  src = fetchurl {
    url = "https://github.com/zenbu-labs/terminal-browser/releases/download/v${version}/terminal-browser-linux-x64.tar.gz";
    # GitHub releaseのassetに載っているdigest
    sha256 = "6277daaabab16711ab3f1961cdffad9efac5e70ac55d5076e2c86496d649d3a4";
  };

  sourceRoot = "terminal-browser";

  nativeBuildInputs = [ autoPatchelfHook ];

  inherit (electron) buildInputs runtimeDependencies autoPatchelfIgnoreMissingDeps;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin
    cp -a . $out/lib/terminal-browser
    ln -s $out/lib/terminal-browser/bin/terminal-browser $out/bin/terminal-browser

    # pixelのherdr連携はsplitした新しいペインのシェルにコマンドを打ち込むので、
    # 終了してもシェルが残る。execで置き換えてペインごと閉じるようにする。
    for f in cli/dist/main.js browser/dist/main.js; do
      substituteInPlace $out/lib/terminal-browser/$f \
        --replace-fail '["pane", "run", newPaneId, (0, shared_1.shellQuote)(command)]' \
                       '["pane", "run", newPaneId, "exec " + (0, shared_1.shellQuote)(command)]'
    done

    runHook postInstall
  '';

  meta = {
    description = "A real browser that runs inside your terminal";
    homepage = "https://github.com/zenbu-labs/terminal-browser";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "terminal-browser";
  };
}
