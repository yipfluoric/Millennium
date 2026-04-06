{
  cmake,
  ninja,
  bun,
  pkg-config,
  git,
  nghttp2,
  libxtst,
  libx11,
  cacert,

  lib,
  pkgsi686Linux,
  stdenv,

  inputs,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "millennium";
  version = "3.0.0";

  src = inputs.millennium-src;

  nativeBuildInputs = [
    cmake
    ninja
    bun
    pkg-config
    git
  ];

  buildInputs = [
    pkgsi686Linux.gtk3
    pkgsi686Linux.libgcc
    pkgsi686Linux.libidn2
    pkgsi686Linux.libpsl
    pkgsi686Linux.openssl
    pkgsi686Linux.brotli
    pkgsi686Linux.xz
    pkgsi686Linux.zstd
    nghttp2
    cacert
    libxtst
    libx11
  ];

  cmakeGenerator = "Ninja";
  cmakeBuildType = "Release";
  enableParallelBuilding = true;

  cmakeFlags = [
    "-DGITHUB_ACTION_BUILD=ON"
    "-DDISTRO_NIX=ON"
    "-DFETCHCONTENT_UPDATES_DISCONNECTED_SNARE=ON"
    "-DCURL_CA_BUNDLE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    "-DCURL_CA_PATH=${cacert}/etc/ssl/certs"
  ];

  postPatch = ''
    mkdir -p deps

    prepare_dep() {
      local name="$1"
      local src="$2"
      echo "[Nix Millennium Build Setup] Preparing dependency: $name"
      cp -r --no-preserve=mode "$src" "deps/$name"
      chmod -R u+w "deps/$name"
    }

    echo "[Nix Millennium Build Setup] Copying all flake inputs to local writable directories"
    ${
      let
        deps = [
          "zlib"
          "luajit"
          "luajson"
          "websocketpp"
          "fmt"
          "json"
          "minizip"
          "curl"
          "incbin"
          "asio"
          "abseil"
          "re2"
          "snare"
        ];
      in
      lib.concatStrings (map (dep: "prepare_dep ${dep} \"${inputs."${dep}-src"}\"\n") deps)
    }

    echo "[Nix Millennium Build Setup] Initializing Git Repos and adding Dummy Commits"
    echo "[Nix Millennium Build Setup] Dummy commits are used to determine versions, but flake inputs strip git history, causing issues"

    export HOME=$(pwd)

    git config --global init.defaultBranch main
    git config --global user.email "nix-build@localhost"
    git config --global user.name "Nix Build"

    git init
    git add .
    git commit -m "Dummy commit for Nix Build" > /dev/null 2>&1

    git init deps/luajit
    git -C deps/luajit add .
    git -C deps/luajit commit -m "Dummy Commit for Luajit Build" > /dev/null 2>&1

    chmod -R u+rwx deps/

    echo "[Nix] Patching src/CMakeLists.txt to replace dynamic target reference..."
    sed -i 's|\$<TARGET_FILE:hhx64>|libmillennium_hhx64.so|g' src/CMakeLists.txt
  '';

  buildPhase = ''
    runHook preBuild
    cmake --preset linux-release
    cmake --build .
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/

    install -Dm755 src/libmillennium_x86.so                             $out/lib/libmillennium_x86.so
    install -Dm755 src/boot/linux/libmillennium_bootstrap_x86.so        $out/lib/libmillennium_bootstrap_x86.so
    install -Dm755 src/libmillennium_luavm_x86                          $out/lib/libmillennium_luavm_x86
    install -Dm755 src/boot/linux/libmillennium_bootstrap_hhx64.so      $out/lib/libmillennium_bootstrap_hhx64.so
    install -Dm755 src/libmillennium_hhx64.so                           $out/lib/libmillennium_hhx64.so
    install -Dm755 src/libmillennium_pvs64                              $out/lib/libmillennium_pvs64

    runHook postInstall
  '';

  meta = {
    homepage = "https://steambrew.app/";
    license = lib.licenses.mit;
    description = "Modding framework to create, manage and use themes/plugins for Steam";

    longDescription = "An open-source low-code modding framework to create, manage and use themes/plugins for the desktop Steam Client without any low-level internal interaction or overhead";

    maintainers = [
      lib.maintainers.trivaris
    ];

    platforms = [
      "x86_64-linux"
    ];
  };
})
