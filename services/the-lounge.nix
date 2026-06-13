{ domain, mkProxy, ... }:

{
  services.thelounge = {
    enable = true;
    extraConfig = {
      reverseProxy = true;
      prefetch = true;
    };
  };

  services.nginx.virtualHosts."irc.${domain}" = mkProxy 9000;
}
