# Modifications overlay - changes to existing packages
_final: prev: {
  # RomM's gunicorn workers die on boot with fastapi-pagination 0.15.16, which
  # mis-detects our fastapi and calls get_body_field() with the wrong keyword.
  # See the patch header for the full story; drop both once fastapi 0.141.1
  # reaches nixos-unstable (nixpkgs#548924, merged to staging 2026-08-11).
  #
  # Scoped to romm's own python (it runs from `passthru.pythonEnv`) so that no
  # other python package on the system loses its binary cache.
  romm = prev.romm.override {
    python3 = prev.python3.override {
      packageOverrides = _pyfinal: pyprev: {
        fastapi-pagination = pyprev.fastapi-pagination.overridePythonAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./fastapi-pagination-old-fastapi.patch ];
        });
      };
    };
  };

  # netdata 2.11.0 build fix: nixpkgs redirects GOPROXY to a local module proxy
  # only in packaging/cmake/Modules/NetdataGoTools.cmake, but 2.11.0 added a
  # "Compressing SNMP trap profile pack" rule in CMakeLists.txt that runs
  # `go run ./cmd/snmptrapprofilegen` with the upstream GOPROXY still hardcoded,
  # so it tries to reach proxy.golang.org and dies in the sandbox. The modules it
  # wants (gomib, klauspost/compress, x/text) are all present in the local proxy,
  # so pointing that rule at it too is enough. Hydra's default build only gets
  # away with it because ninja happens to populate GOPATH first.
  # Drop once nixpkgs substitutes GOPROXY repo-wide.
  netdata = prev.netdata.overrideAttrs (
    finalAttrs: prevAttrs: {
      preConfigure = prevAttrs.preConfigure + ''
        substituteInPlace CMakeLists.txt \
          --replace-warn \
            'GOPROXY=https://proxy.golang.org,direct' \
            'GOPROXY=file://${finalAttrs.passthru.netdata-go-modules}'
      '';
    }
  );
}
