{ config, domain, ... }:

let
  alertmanagerNtfyPort = 8087;
in 
{
  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";

    configuration = {
      route = {
        receiver = "ntfy";
        group_by = [ "..." ];
        group_wait = "0s";
        group_interval = "1s";
        repeat_interval = "2h";
      };

      receivers = [
        {
          name = "ntfy";
          webhook_configs = [ { url = "http://127.0.0.1:${toString alertmanagerNtfyPort}/hook"; } ];
        }
      ];
    };
  };

  services.prometheus.alertmanager-ntfy = {
    enable = true;
    settings = {
      http.addr = "127.0.0.1:${toString alertmanagerNtfyPort}";
      ntfy = {
        baseurl = "https://ntfy.${domain}";
        notification.topic = "alertmanager";
      };
    };
  };

  services.nginx.virtualHosts."alertmanager.${domain}" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}/";
    };
  };
}