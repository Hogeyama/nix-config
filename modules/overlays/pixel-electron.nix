# terminal-browserが同梱しているzenbu-labsのpixel(パッチ済みElectron)のための依存。
# 同じpixelを使うterminal-code(tode)を足すときにも使い回せるよう分けてある。
# autoPatchelfに渡す顔ぶれはchatgptと同じ。
{ lib
, stdenv
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
, libdrm
, libgbm
, libglvnd
, libnotify
, libpulseaudio
, libx11
, libxcb
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxkbcommon
, libxrandr
, nspr
, nss
, pango
, systemd
}:
{
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
    libdrm
    libgbm
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
    stdenv.cc.cc.lib
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
    # KDEのネイティブダイアログ用の差し込み。dlopenに失敗すればGTKに落ちる。
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    # native node moduleのmusl版prebuild。glibc版が選ばれるので解決不要。
    "libc.musl-x86_64.so.1"
  ];
}
