{ ... }:

{
  services.alloy = {
    enable = true;
    extraFlags = [ "--stability.level=generally-available" ];
  };

  environment.etc."alloy/config.alloy".text = ''
    loki.source.journal "systemd" {
      max_age = "12h"
      labels = {
        job  = "systemd-journal",
        host = "bifrost",
      }
      forward_to = [loki.write.default.receiver]
      relabel_rules = loki.relabel.journal.rules
    }

    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
    }

    loki.write "default" {
      endpoint {
        url = "http://127.0.0.1:3030/loki/api/v1/push"
      }
    }
  '';
}
