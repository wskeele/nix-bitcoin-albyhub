{ buildGoModule
, fetchFromGitHub
, secp256k1
, stdenv
, fetchYarnDeps
, fixup-yarn-lock
, yarn
, nodejs_20
, typescript
, pkg-config
, lib
}:
let
  version = "1.17.0";
  src = fetchFromGitHub {
    owner = "getAlby";
    repo = "hub";
    rev = "v${version}";
    sha256 = "sha256-RjoBYP+vsNuKQuFOcNzhdByj7FdpUTcqZp2EznYKxY4=";
  };
  frontend = stdenv.mkDerivation (finalAttrs: {
    inherit version;
    pname = "albyhub-frontend";

    src = "${src}/frontend";

    offlineCache = fetchYarnDeps {
      yarnLock = finalAttrs.src + "/yarn.lock";
      hash = "sha256-SStTJGqeqPvXBKjFMPjKEts+jg6A9Vaqi+rZkr/ytdc=";
    };

    nativeBuildInputs = [
      yarn
      typescript
      fixup-yarn-lock
      nodejs_20
    ];

    configurePhase = ''
      runHook preConfigure
      export HOME=$NIX_BUILD_TOP/fake_home

      yarn config --offline set yarn-offline-mirror $offlineCache
      fixup-yarn-lock yarn.lock
      yarn install --offline --frozen-lockfile --ignore-scripts --no-progress --non-interactive

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild

      patchShebangs node_modules
      export PATH="$PWD/node_modules/.bin:$PATH"
      sed -i 's/yarn/yarn --offline/g' package.json
      yarn --offline build:http

      runHook postBuild
    '';

    installPhase = ''
      mv dist $out/
    '';
  });
in
buildGoModule {

  inherit version src;

  pname = "albyhub";

  preBuild = ''
    mkdir ./frontend/dist
    cp -r ${frontend}/* ./frontend/dist
  '';

  postInstall = ''
    # Must copy LDK libs
    workdir=$(mktemp -d)
    cp go.mod $workdir
    cp go.sum $workdir
    cp build/docker/copy_dylibs.sh $workdir
    pushd $workdir
    bash copy_dylibs.sh $GOARCH
    rm go.mod go.sum copy_dylibs.sh
    mkdir -p $out/lib
    cp -rT . $out/lib
    popd

    mv $out/bin/http $out/bin/alby-hub
    patchelf --shrink-rpath --allowed-rpath-prefixes /nix/store $out/bin/alby-hub
  '';

  proxyVendor = true;
  vendorHash = "sha256-b9GRrWfr+6uGsapPx0wY3F8N3g6i4/O5svxC49+JsGY=";
}
