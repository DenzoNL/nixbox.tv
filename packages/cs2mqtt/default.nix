{ lib, fetchFromGitHub, buildDotnetModule, dotnetCorePackages }:

buildDotnetModule rec {
  pname = "cs2mqtt";
  version = "1.6.3";

  src = fetchFromGitHub {
    owner = "lupusbytes";
    repo = "cs2mqtt";
    rev = "v${version}";
    sha256 = "sha256-gaWponTnmcCfCpg59bZ0RxjwAW6NOqYRde4NbGbPwX4="; # Replace with correct hash
  };

  dotnet-sdk = dotnetCorePackages.sdk_9_0;
  nugetDeps = ./deps.json;

  projectFile = "src/LupusBytes.CS2.GameStateIntegration.Api/LupusBytes.CS2.GameStateIntegration.Api.csproj";

  meta = with lib; {
    description = "CS:GO/CS2 game state integration to MQTT bridge";
    homepage = "https://github.com/LupusBytes/cs2mqtt";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
