# Modifications overlay - changes to existing packages
final: prev: 
let
  version = "0.16.5";
in
{
  # libtorrent override - specific version needed for rtorrent
  libtorrent-rakshasa = prev.libtorrent-rakshasa.overrideAttrs (_: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "libtorrent";
      rev = "v${version}";
      hash = "sha256-zBMenewDtUyhOAQrIKejiShGWDeIA+7U1heyOKfAjio=";
    };
  });

  # rtorrent override - matching version with libtorrent
  rtorrent = prev.rtorrent.overrideAttrs (old: {
    inherit version;
    src = prev.fetchFromGitHub {
      owner = "rakshasa";
      repo = "rtorrent";
      rev = "v${version}";
      hash = "sha256-zncal17A4/+WGU3L8iJVSMJtKTKNmMHCXJ2O7Za2VOE=";
    };
  });
}