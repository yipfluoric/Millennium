{
  cmake,
  ninja,
  bun,
  pkg-config,
  git,
  cacert,

  lib,
  stdenv,

  inputs,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "millennium-64";
  version = "3.0.0";

  src = inputs.millennium-src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    git
    bun
  ];

  buildInputs = [
    cacert
  ];

  cmakeGenerator = "Ninja";
  cmakeBuildType = "Release";
  enableParallelBuilding = true;

  cmakeFlags = [
    "-DGITHUB_ACTION_BUILD=ON"
    "-DDISTRO_NIX=ON"   
    "-DFETCHCONTENT_SOURCE_DIR_SNARE=${inputs.snare-src}"
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
    git add .w
    git commit -m "Dummy commit for build" > /dev/null 2>&1

    chmod -R u+rwx deps
    
    echo "[Nix] Patching CMakeLists to IGNORE 32-bit source..."
    sed -i '/add_subdirectory.*src)/s/^/#/' CMakeLists.txt
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
    install -Dm755 src/hhx64/libmillennium_hhx64.so                     $out/lib/libmillennium_hhx64.so
    install -Dm755 src/boot/linux/libmillennium_bootstrap_hhx64.so      $out/lib/libmillennium_bootstrap_hhx64.so
    install -Dm755 libmillennium_pvs64                                  $out/lib/libmillennium_pvs64
    runHook postInstall
  '';

  meta = {
    homepage = "https://steambrew.app/";
    license = lib.licenses.mit;
    description = "Main Millennium Library used to load and apply plugins and themes";

    longDescription = "An open-source low-code modding framework to create, manage and use themes/plugins for the desktop Steam Client without any low-level internal interaction or overhead";

    maintainers = [
      lib.maintainers.trivaris
    ];

    platforms = [
      "x86_64-linux"
    ];
  };
})