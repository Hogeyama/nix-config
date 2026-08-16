{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, python3
, wrapGAppsHook3
, alsa-lib
, at-spi2-atk
, at-spi2-core
, atk
, cairo
, cups
, dbus
, expat
, gdk-pixbuf
, glib
, gtk3
, libgbm
, libglvnd
, libnotify
, libpulseaudio
, libusb1
, libx11
, libxcb
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxkbcommon
, libxrandr
, coreutils
, nspr
, nss
, pango
, systemd
, xdg-utils
}:
# 公式が提供するのはdebのみ(https://developers.openai.com/codex/app)なので展開して
# patchelfする。中身はElectronアプリで、resources/以下にcodex CLIとripgrepの
# バイナリ、prebuiltのnative node moduleを同梱している。
stdenv.mkDerivation {
  pname = "chatgpt";
  version = "26.810.52044";

  src = fetchurl {
    # latest固定のURLしか公開されていない。更新時は再ダウンロードしてhashを取り直す:
    #   nix store prefetch-file --json <url> | jq -r .hash
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
    hash = "sha256-cIoVobt24rt/DjduUUU5H6J3rTpkBXwdMlN73CobTm4=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    python3
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libgbm
    libusb1
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    (lib.getLib systemd) # libudev.so.1
  ];

  # dlopenされるためDT_NEEDEDに現れないもの。
  runtimeDependencies = [
    (lib.getLib systemd)
    libglvnd
    libnotify
    libpulseaudio
  ];

  autoPatchelfIgnoreMissingDeps = [
    # libqt{5,6}_shim.soはKDE上でネイティブのファイルダイアログを使うためだけの
    # 差し込みで、dlopenに失敗すればGTK実装にフォールバックする。このためだけに
    # Qt5とQt6の両方をclosureへ引き込むのは割に合わないので解決しない。
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    # native node moduleのmusl版prebuild。glibc版が隣に同梱されており
    # そちらが選ばれるので、musl版は解決できなくてよい。
    "libc.musl-x86_64.so.1"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  # gappsWrapperArgsを自前のmakeWrapperに渡したいので自動ラップは切る。
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    # 展開後のツリーは以降不要なので、コピーではなく移動する。1.4GBの二重確保を
    # 避けないとビルドのピーク使用量が3GB近くなる。
    mkdir -p $out/lib
    mv usr/lib/chatgpt $out/lib/chatgpt
    mv usr/share $out/share
    rm -rf $out/share/doc $out/share/lintian

    chmod +w $out/lib/chatgpt/resources/app.asar
    python3 ${./patch-asar.py} \
      $out/lib/chatgpt/resources/app.asar \
      /node_modules/@parcel/watcher/index.js \
      ${./parcel-watcher-index.js}

    mkdir -p $out/bin
    substitute ${./launcher.sh} $out/bin/chatgpt \
      --subst-var-by app $out/lib/chatgpt \
      --subst-var-by name "$(basename $out)"
    chmod +x $out/bin/chatgpt

    wrapProgram $out/bin/chatgpt \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ coreutils xdg-utils ]} \
      --add-flags "--ozone-platform-hint=auto"

    substituteInPlace $out/share/applications/chatgpt.desktop \
      --replace-fail "Exec=chatgpt" "Exec=$out/bin/chatgpt"

    runHook postInstall
  '';

  meta = {
    description = "ChatGPT desktop app by OpenAI";
    homepage = "https://developers.openai.com/codex/app";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "chatgpt";
  };
}
