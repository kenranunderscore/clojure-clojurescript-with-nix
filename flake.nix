{
  description = "Showcasing how to build Clojure + ClojureScript applications purely with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { system, inputs', ... }:
        let
          pkgs = inputs'.nixpkgs.legacyPackages;
          npmRoot = ./the-app;
        in
        {
          formatter = pkgs.nixfmt-rfc-style;
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.clojure
              pkgs.nodejs
              # This works as long as there's no custom `shellHook`, but you may
              # just call it manually in that case
              pkgs.importNpmLock.hooks.linkNodeModulesHook
            ];
            # Set `npmRoot` here so that the node_modules link will be created
            # in the correct subdirectory. Also assumes that `nix develop` is
            # called from the root/flake directory (which, for instance,
            # `direnv` does by default).
            npmRoot = builtins.baseNameOf npmRoot;
            npmDeps = pkgs.importNpmLock.buildNodeModules {
              inherit npmRoot;
              inherit (pkgs) nodejs;
            };
          };
        };
    };
}
