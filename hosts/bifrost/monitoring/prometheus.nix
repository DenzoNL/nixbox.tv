{ config, ... }:

let
  nodeExporterRules = builtins.toFile "node-exporter.yml" (builtins.readFile ./prometheus-rules/node-exporter.yml);
in
{
  services.prometheus = {
    enable = true;
    port = 9001;
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };
    retentionTime = "365d";
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    ruleFiles = [ nodeExporterRules ];
    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.prometheus.alertmanager.port}" ]; }
        ];
      }
    ];
    extraFlags = [ "--web.enable-admin-api" ];
    scrapeConfigs = [
      {
        job_name = "alertmanager";
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.prometheus.alertmanager.port}" ]; }
        ];
      }
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            labels.instance = "bifrost";
          }
          {
            targets = [ "nixbox:${toString config.services.prometheus.exporters.node.port}" ];
            labels.instance = "nixbox";
          }
        ];
      }
    ];
  };
}