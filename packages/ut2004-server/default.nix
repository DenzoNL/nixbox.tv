{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, p7zip
}:

stdenv.mkDerivation {
  pname = "ut2004-server";
  version = "3369.3";

  src = fetchurl {
    url = "https://archive.org/download/ut2004-server/dedicatedserver3369.3-bonuspack.zip";
    sha256 = "sha256-EjMm53WkLFYoabf5Ol769SPkR564L0ksPBFJjgwTDWo=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    p7zip
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    7z x -y $src
    cd dedicatedserver3369.3-bonuspack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/ut2004
    cp -r * $out/ut2004/

    # Make binaries executable
    chmod +x $out/ut2004/System/*-bin*

    runHook postInstall
  '';

  postFixup = ''
    # Create wrapper for ucc-bin (runs after autoPatchelfHook)
    makeWrapper $out/ut2004/System/ucc-bin-linux-amd64 $out/bin/ucc-bin \
      --chdir "$out/ut2004/System"
  '';

  meta = with lib; {
    description = "Unreal Tournament 2004 Dedicated Server";
    longDescription = ''
      Unreal Tournament 2004 is a multiplayer first-person shooter that combines
      the kill-or-be-killed experience of gladiatorial combat with cutting-edge
      technology. This package contains the dedicated server binaries for hosting
      UT2004 game servers.
    '';
    homepage = "https://www.unrealtournament.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ucc-bin";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
