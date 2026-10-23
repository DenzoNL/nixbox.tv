# Modifications overlay - changes to existing packages
_final: prev:
let
  # rtorrent/libtorrent are pinned to the release the private trackers accept;
  # keep both on the same version (rtorrent's build picks up libtorrent-rakshasa
  # from the final package set, so overriding it here is enough).
  rtorrentVersion = "0.16.23";
in
{
  libtorrent-rakshasa = prev.libtorrent-rakshasa.overrideAttrs (_: {
    version = rtorrentVersion;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "libtorrent";
      tag = "v${rtorrentVersion}";
      hash = "sha256-6obiCOSkn0S/x8QNdAtVQvt9StT8h+x1qeagg/0w7aA=";
    };
  });

  rtorrent = prev.rtorrent.overrideAttrs (_: {
    version = rtorrentVersion;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "rtorrent";
      tag = "v${rtorrentVersion}";
      hash = "sha256-+cHgHtjqmnz6oBrbNruG9RNm3iqMf4HxuIOzR1NOJ4Q=";
    };
  });

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

  # unifi 10.6.106 added lib/native/Linux/x86_64/libubnt_webrtc_jni.so, which
  # links libstdc++ and libgcc_s. nixpkgs builds the package with stdenvNoCC and
  # only gives autoPatchelf `systemd`, so the build dies with "auto-patchelf
  # could not satisfy dependency libstdc++.so.6". Hand it the gcc runtime libs.
  # Drop once nixpkgs adds them to the package itself.
  unifi = prev.unifi.overrideAttrs (prevAttrs: {
    buildInputs = (prevAttrs.buildInputs or [ ]) ++ [ prev.stdenv.cc.cc.lib ];
  });
}
