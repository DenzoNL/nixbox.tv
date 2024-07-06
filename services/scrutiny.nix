{ ... }:

{
  services.scrutiny = {
    enable = true;
    collector.enable = true;
    settings.web.listen.port = 8181;
    settings.notify.urls = [
      "ntfy://ntfy.nixbox.tv/nixbox"
    ];
  };

  services.nginx.virtualHosts."scrutiny.nixbox.tv" = {
    locations."/" = {
      proxyPass = "http://localhost:8181/";
    };
  };
}