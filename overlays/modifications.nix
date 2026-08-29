# Modifications overlay - changes to existing packages
_final: prev: {
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
