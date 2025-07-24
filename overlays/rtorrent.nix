self: super: 
let
  version = "0.15.1";
in
{
  libtorrent = super.libtorrent.overrideAttrs (_: {
    inherit version;
    src = super.fetchFromGitHub {
      owner = "rakshasa";
      repo = "libtorrent";
      rev = "v${version}";
      hash = "sha256-ejDne7vaV+GYP6M0n3VAEva4UHuxRGwfc2rgxf7U/EM=";
    };
  });

  rtorrent = super.rtorrent.overrideAttrs (old: {
    inherit version;
    src = super.fetchFromGitHub {
      owner = "rakshasa";
      repo = "rtorrent";
      rev = "v${version}";
      hash = "sha256-5ewAeoHvKcZ+5HTMlXLTu63JE3plKATvZToFEDZ9vOs=";
    };
  });
}
