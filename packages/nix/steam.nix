{
  steam,
  openssl,
  pkgsi686Linux,

  lib,
  millennium,

  extraPkgs ? (_: [ ]),
  extraLibraries ? (_: [ ]),
  extraEnv ? { },
  extraProfile ? "",
  ...
}@args:
let
  millenniumPkgs = [
    pkgsi686Linux.openssl
  ];

  millenniumLibs = [
    millennium
    pkgsi686Linux.openssl
    openssl
  ];

  millenniumEnv = {
    OPENSSL_CONF = "/dev/null";
    STEAM_RUNTIME_LOGGER = "0";
    MILLENNIUM_RUNTIME_PATH = "${millennium}/lib/libmillennium_x86.so";
  };

  millenniumProfile = ''

    rm -rf ~/.local/share/Steam/ubuntu12_32/libXtst.so.6
    ln -s ${millennium}/lib/libmillennium_bootstrap_x86.so "$HOME/.local/share/Steam/ubuntu12_32/libXtst.so.6"
  '';

  upstreamArgs = removeAttrs args [
    "steam"
    "openssl"
    "pkgsi686Linux"
    "millennium"
  ];
in
steam.override (
  upstreamArgs
  // {
    extraPkgs = pkgs: millenniumPkgs ++ (extraPkgs pkgs);
    extraLibraries = pkgs: millenniumLibs ++ (extraLibraries pkgs);
    extraEnv = extraEnv // millenniumEnv;
    extraProfile = millenniumProfile + "\n" + extraProfile;
  }
)
