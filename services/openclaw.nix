{ domain, ... }:

{
  services.nginx.virtualHosts."openclaw.${domain}" = {
    locations."/" = {
      proxyPass = "http://openclaw:18789/";
      proxyWebsockets = true;
    };
  };
}
