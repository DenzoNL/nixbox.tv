# Modifications overlay - changes to existing packages
final: prev: 
let
  version = "0.15.1";
in
{
  # libtorrent override - specific version needed for rtorrent
  libtorrent-rakshasa = prev.libtorrent-rakshasa.overrideAttrs (_: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "libtorrent";
      rev = "v${version}";
      hash = "sha256-ejDne7vaV+GYP6M0n3VAEva4UHuxRGwfc2rgxf7U/EM=";
    };
  });

  # rtorrent override - matching version with libtorrent
  rtorrent = prev.rtorrent.overrideAttrs (old: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "rtorrent";
      rev = "v${version}";
      hash = "sha256-5ewAeoHvKcZ+5HTMlXLTu63JE3plKATvZToFEDZ9vOs=";
    };
  });
}