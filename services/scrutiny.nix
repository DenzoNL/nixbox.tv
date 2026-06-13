{ domain, mkProxy, ... }:

{
  services.scrutiny = {
    enable = true;
    collector.enable = true;
    settings.web.listen.port = 8181;
    settings.notify.urls = [
      "ntfy://ntfy.nixbox.tv/nixbox"
    ];
  };

  services.nginx.virtualHosts."scrutiny.${domain}" = mkProxy 8181;
}
