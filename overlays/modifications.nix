# Modifications overlay - changes to existing packages
_final: prev:
let
  version = "0.16.11";
in
{
  # libtorrent override - specific version needed for rtorrent
  libtorrent-rakshasa = prev.libtorrent-rakshasa.overrideAttrs (_: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "libtorrent";
      rev = "v${version}";
      hash = "sha256-T8Td2bQlO21ieXdJ+oZ4GytJiGxb9AcgBsygl8yMrpI=";
    };
  });

  # rtorrent override - matching version with libtorrent
  rtorrent = prev.rtorrent.overrideAttrs (_: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "rtorrent";
      rev = "v${version}";
      hash = "sha256-OEIJMBj1UfIOpR1w8c8ztKWJVD5hKxiJaxweF7mBRNM=";
    };
  });
}
