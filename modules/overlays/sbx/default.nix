{ lib
, fetchurl
, stdenv
, stdenvNoCC
, autoPatchelfHook
, makeWrapper
, e2fsprogs
, glibc
, lz4
, zlib
, zstd
, xxhash
}:
stdenvNoCC.mkDerivation rec {
  pname = "sbx";
  version = "0.43.0";

  src = fetchurl {
    url = "https://github.com/docker/sbx-releases/releases/download/v${version}/DockerSandboxes-linux-amd64.tar.gz";
    sha256 = "sha256-PrFbhETpaaqo1jclC+8PK/kMsDCroKcBala45fzdJf4=";
  };

  sourceRoot = "docker-sbx";

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  # mkfs.erofs: lz4/zlib/zstd/xxhash, libsailor.so: libgcc_s
  buildInputs = [ glibc lz4 zlib zstd xxhash stdenv.cc.cc.lib ];

  # sbx は実行ファイルから ../libexec を絶対パス解決するため、
  # 公式 install.sh と同じ bin/libexec レイアウトにする。
  # wrapProgram しても実体は $out/bin/.sbx-wrapped に残るので解決は壊れない。
  installPhase = ''
    runHook preInstall

    install -Dm755 sbx $out/bin/sbx
    install -Dm755 containerd-shim-nerdbox-v1 $out/libexec/containerd-shim-nerdbox-v1
    install -Dm755 containerd-shim-nerdbox-gpu-v1 $out/libexec/containerd-shim-nerdbox-gpu-v1
    install -Dm755 mkfs.erofs $out/libexec/mkfs.erofs
    install -Dm644 nerdbox-kernel-* -t $out/libexec/
    install -Dm644 nerdbox-rootfs-*.erofs -t $out/libexec/
    install -Dm755 libsailor.so $out/libexec/lib/libsailor.so

    # sandboxd がホストで mkfs.ext4 を叩く
    wrapProgram $out/bin/sbx \
      --prefix PATH : ${lib.makeBinPath [ e2fsprogs ]}

    runHook postInstall
  '';

  meta = {
    description = "Docker Sandboxes: run AI coding agents in isolated microVMs";
    homepage = "https://github.com/docker/sbx-releases";
    mainProgram = "sbx";
    platforms = [ "x86_64-linux" ];
  };
}
