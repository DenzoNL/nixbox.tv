{ domain, mkProxy, ... }:

{
  services.karakeep = {
    enable = true;
    browser = {
      enable = true;
    };
    meilisearch = {
      enable = true;
    };
    extraEnvironment = {
      PORT = "8765";
      DISABLE_NEW_RELEASE_CHECK = "true";
    };
  };

  services.nginx.virtualHosts."karakeep.${domain}" = mkProxy 8765;
}
