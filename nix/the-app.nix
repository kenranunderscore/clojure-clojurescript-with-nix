{
  pkgs,
  clj-builder,
  clojure,
  nodejs,
  cljDeps,
  npmDeps,
  src,
  ...
}:

pkgs.stdenv.mkDerivation {
  inherit src;
  name = "example-uber";

  nativeBuildInputs = [
    clojure
    nodejs
    clj-builder
  ];

  preBuildPhases = [ "preBuildPhase" ];
  preBuildPhase = "clj-builder patch-git-sha $(pwd)";
  buildPhase = ''
    export HOME=$(pwd)
    export JAVA_TOOL_OPTIONS="-Duser.home=$HOME"

    ln -s ${cljDeps}/.m2 .m2
    ln -s ${cljDeps}/.gitlibs .gitlibs
    ln -s ${cljDeps}/.clojure .clojure
    export GITLIBS="$HOME/.gitlibs"
    export CLJ_CONFIG="$HOME/.clojure"
    export CLJ_CACHE="$TMP/cp_cache"

    ln -s ${npmDeps}/node_modules .

    clj -T:build uber
  '';

  doCheck = true;
  checkPhase = "echo 'Could run a custom `clj -T:build test` command here for instance'";

  installPhase = ''
    mkdir -p $out/lib
    cp ./target/app.jar $out/lib/app.jar
  '';
}
