# TODO

- [ ] Drop the `netdata` entry in `overlays/modifications.nix` once nixpkgs substitutes `GOPROXY` repo-wide instead of only in `packaging/cmake/Modules/NetdataGoTools.cmake`. netdata 2.11.0 added a "Compressing SNMP trap profile pack" rule in `CMakeLists.txt` that runs `go run ./cmd/snmptrapprofilegen` with `GOPROXY=https://proxy.golang.org,direct` hardcoded, so it tries to hit the network and fails in the sandbox. Hydra's free build only passes because ninja happens to populate `$GOPATH/pkg/mod` first; our `withCloudUi = true` build is unfree, never cached, and always builds locally — so it always loses that race. (`NetdataIBMPlugin.cmake` has the same unsubstituted line, harmless while that plugin is off.)

