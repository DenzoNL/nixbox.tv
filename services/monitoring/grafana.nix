{ config, ... }: 

{
  sops.secrets = {
    "grafana/admin_user" = {
      owner = config.users.users.grafana.name;
    };
    "grafana/admin_password" = {
      owner = config.users.users.grafana.name;
    };
    "grafana/admin_email" = {
      owner = config.users.users.grafana.name;
    };
    "grafana/smtp_password" = {
      owner = config.users.users.grafana.name;
    };
  };

  # grafana configuration
  services.grafana = {
    enable = true;

    settings = {
      server = {
        domain = "grafana.nixbox.tv";
        http_port = 2342;
        http_addr = "127.0.0.1";
      };

      security = {
        admin_user = "$__file{${config.sops.secrets."grafana/admin_user".path}}";
        admin_password = "$__file{${config.sops.secrets."grafana/admin_password".path}}";
        admin_email = "$__file{${config.sops.secrets."grafana/admin_email".path}}";
      };

      smtp = {
        enabled = true;
        host = "smtp.gmail.com:465";
        user = "denzonl@gmail.com";
        password = "$__file{${config.sops.secrets."grafana/smtp_password".path}}";
        from_address = "denzonl@gmail.com";
      };
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
    locations."/" = {
      proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}/";
      proxyWebsockets = true;
    };
  };
}