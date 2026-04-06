{
  description = "Nix Build for Millennium";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    millennium-src.url = "github:SteamClientHomebrew/Millennium/next";
    millennium-src.flake = false;

    zlib-src.url = "github:zlib-ng/zlib-ng/2.2.5";
    luajit-src.url = "github:SteamClientHomebrew/LuaJIT/v2.1";
    luajson-src.url = "github:SteamClientHomebrew/LuaJSON/master";
    websocketpp-src.url = "github:zaphoyd/websocketpp/0.8.2";
    fmt-src.url = "github:fmtlib/fmt/12.0.0";
    json-src.url = "github:nlohmann/json/v3.12.0";
    minizip-src.url = "github:zlib-ng/minizip-ng/4.0.10";
    curl-src.url = "github:curl/curl/curl-8_13_0";
    incbin-src.url = "github:graphitemaster/incbin/22061f51fe9f2f35f061f85c2b217b55dd75310d";
    asio-src.url = "github:chriskohlhoff/asio/asio-1-30-0";
    libsnare-src.url = "github:shdwmtr/libsnare.h";

    abseil-src.url = "github:abseil/abseil-cpp/20240722.0";
    re2-src.url = "github:google/re2/2025-11-05";

    zlib-src.flake = false;
    luajit-src.flake = false;
    luajson-src.flake = false;
    websocketpp-src.flake = false;
    fmt-src.flake = false;
    json-src.flake = false;
    minizip-src.flake = false;
    curl-src.flake = false;
    incbin-src.flake = false;
    asio-src.flake = false;
    libsnare-src.flake = false;
    
    abseil-src.flake = false;
    re2-src.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      millennium-src,
      ...
    }@inputs:
    {
      packages.x86_64-linux =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };

          millennium-deps = {
            inherit inputs;
          };

          packages = {
            default             = packages.millennium-steam;
            millennium          = pkgs.callPackage ./millennium.nix     ( millennium-deps );
            millennium-steam    = pkgs.callPackage ./steam.nix          { inherit (packages) millennium; };
          };
        in
        packages;

      overlays.default = final: prev: {
        inherit (self.packages.${prev.stdenv.hostPlatform.system}) millennium-steam;
      };
    };
}
