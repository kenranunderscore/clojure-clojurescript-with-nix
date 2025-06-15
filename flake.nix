{
  description = "Showcasing how to build Clojure + ClojureScript applications purely with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    clj-nix = {
      url = "github:kenranunderscore/clj-nix/symlink-clojure-deps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { system, inputs', ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.clj-nix.overlays.default ];
          };
          inherit (pkgs) lib;
          appRoot = "the-app";
          appSrc = ./. + "/${appRoot}";
          npmDeps = pkgs.importNpmLock.buildNodeModules {
            npmRoot = appSrc;
            inherit (pkgs) nodejs;
          };
        in
        {
          formatter = pkgs.nixfmt-rfc-style;

          packages = {
            default = inputs'.clj-nix.packages.mkCljBin {
              name = "example/example";
              main-ns = "example.backend.main";
              projectSrc = appSrc;
              lockfile = appSrc + /deps-lock.json;
              symlinkDeps = true;
              nativeBuildInputs = [ pkgs.nodejs ];
              buildCommand = ''
                ln -s ${npmDeps}/node_modules .
                clj -T:build uber
              '';
            };
            lock-clojure-deps = pkgs.writeShellScriptBin "lock-clojure-deps" ''
              cd ${appRoot}
              tmpdeps=$(mktemp --tmpdir)
              cat deps.edn >"$tmpdeps"
              ${lib.getExe pkgs.gnused} 's|:mvn/local-repo.*$||' -i "$tmpdeps"
              ${lib.getExe inputs'.clj-nix.packages.deps-lock} --deps-include "$tmpdeps"
            '';
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.clojure
              pkgs.nodejs
              # This would work on its own as long as there's no custom
              # `shellHook`, but you may just call it manually in that case as
              # below.
              pkgs.importNpmLock.hooks.linkNodeModulesHook
            ];
            shellHook = ''
              echo [shell setup] preparing environment...
              linkNodeModulesHook
              export GITLIBS=$(pwd)/${appRoot}/.gitlibs
              export CLJ_CONFIG=$(pwd)/${appRoot}/.clj
              echo [shell setup] done
            '';
            # Set `npmRoot` here so that the node_modules link will be created
            # in the correct subdirectory. Also assumes that `nix develop` is
            # called from the root/flake directory (which, for instance,
            # `direnv` does by default).
            npmRoot = appRoot;
            inherit npmDeps;
          };
        };
    };
}
