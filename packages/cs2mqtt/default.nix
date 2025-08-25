{ lib, fetchFromGitHub, buildDotnetModule, dotnetCorePackages }:

buildDotnetModule rec {
  pname = "cs2mqtt";
  version = "1.6.8";

  src = fetchFromGitHub {
    owner = "lupusbytes";
    repo = "cs2mqtt";
    rev = "v${version}";
    sha256 = "sha256-JniE7PduDty3RPmVqP0TdsdI8hAeom4V0SwmRXodg4Y=";
  };

  dotnet-sdk = dotnetCorePackages.sdk_9_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_9_0;

  nugetDeps = ./deps.json;
  projectFile = "src/LupusBytes.CS2.GameStateIntegration.Api/LupusBytes.CS2.GameStateIntegration.Api.csproj";

  meta = with lib; {
    description = "CS:GO/CS2 game state integration to MQTT bridge";
    homepage = "https://github.com/LupusBytes/cs2mqtt";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
