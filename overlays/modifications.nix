# Modifications overlay - changes to existing packages
final: prev: 
let
  version = "0.16.1";
in
{
  # libtorrent override - specific version needed for rtorrent
  libtorrent-rakshasa = prev.libtorrent-rakshasa.overrideAttrs (_: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "libtorrent";
      rev = "v${version}";
      hash = "sha256-dVKd9u7etLhaNKrtedtIFsUgJ+KuP/vCFn1skY/wZeY=";
    };
  });

  # rtorrent override - matching version with libtorrent
  rtorrent = prev.rtorrent.overrideAttrs (old: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "rtorrent";
      rev = "v${version}";
      hash = "sha256-8FVgUnWmuBgFC9W35LzK6Y7bkYGYzzuPDPAzPSnD9ys=";
    };
  });
}