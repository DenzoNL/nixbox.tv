{ config, ... }: {
  # grafana configuration
  services.grafana = {
    enable = true;
    settings.server = {
      domain = "grafana.nixbox.tv";
      http_port = 2342;
      http_addr = "127.0.0.1";
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };
  
  # nginx reverse proxy
  services.nginx.virtualHosts."grafana.nixbox.tv" = {
    forceSSL = true;
    enableACME = true;

    http2 = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:2342";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host grafana.nixbox.tv;
      '';
    };

    locations."/api/live/" = {
      proxyPass = "http://127.0.0.1:2342";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host grafana.nixbox.tv;
      '';
    };
  };
}