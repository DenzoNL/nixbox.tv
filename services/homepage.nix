{ config, domain, ... }:

{
  sops.secrets."homepage" = {};

  services.homepage-dashboard = {
    enable = true;
    environmentFile = config.sops.secrets."homepage".path;
    settings = {
      base = "https://${domain}";
      title = "${domain}";
      useEqualHeights = true;
      layout = {
        Media = {
          style = "row";
          columns = "4";
        };
        System = {
          style = "row";
          columns = "4";
        };
      };
    };
    widgets = [
      {
        search = {
          focus = true;
          provider = "google";
          showSearchSuggestions = true;
          target = "_blank";
        };
      }
      {
        resources = {
          label = "System";
          cpu = true;
          cputemp = true;
          units = "metric";
          memory = true;
        };
      }
      {
        openmeteo = {
          label = "{{HOMEPAGE_VAR_WEATHER_LOCATION}}";
          latitude = "{{HOMEPAGE_VAR_WEATHER_LATITUDE}}";
          longitude = "{{HOMEPAGE_VAR_WEATHER_LONGITUDE}}";
          timezone = "{{HOMEPAGE_VAR_WEATHER_TIMEZONE}}";
          cache = "5";
          units = "metric";
          format = {
            maximumFractionDigits = "1";
          };
        };
      }
    ];
    services = [
      {
        "Media" = [
          {
            Plex = {
              icon = "plex.png";
              href = "https://tautulli.${domain}";
              siteMonitor = "http://localhost:8282/home";
              widget = {
                type = "tautulli";
                url = "http://localhost:8282";
                key = "{{HOMEPAGE_VAR_TAUTULLI_API_KEY}}";
                enableUser = true;
                showEpisodeNumber = true;
              };
            };
          }
          {
            Sonarr = {
              icon = "sonarr.png";
              href = "https://sonarr.${domain}";
              siteMonitor = "http://localhost:8989/ping";
              widget = {
                type = "sonarr";
                url = "http://localhost:8989";
                key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
              };
            };
          }
          {
            Radarr = {
              icon = "radarr.png";
              href = "https://radarr.${domain}";
              siteMonitor = "http://localhost:7878/ping";
              widget = {
                type = "radarr";
                url = "http://localhost:7878";
                key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
              };
            };
          }
          {
            Lidarr = {
              icon = "lidarr.png";
              href = "https://lidarr.${domain}";
              siteMonitor = "http://localhost:8686/ping";
              widget = {
                type = "lidarr";
                url = "http://localhost:8686";
                key = "{{HOMEPAGE_VAR_LIDARR_API_KEY}}";
              };
            };
          }
          {
            Readarr = {
              icon = "readarr.png";
              href = "https://readarr.${domain}";
              siteMonitor = "http://localhost:8787/ping";
              widget = {
                type = "readarr";
                url = "http://localhost:8787";
                key = "{{HOMEPAGE_VAR_READARR_API_KEY}}";
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.png";
              href = "https://prowlarr.${domain}";
              siteMonitor = "http://localhost:9696/ping";
              widget = {
                type = "prowlarr";
                url = "http://localhost:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
              };
            };
          }
          {
            Flood = {
              icon = "flood.png";
              href = "https://flood.${domain}";
              siteMonitor = "http://localhost:3000";
              widget = {
                type = "flood";
                url = "http://localhost:3000";
                username = "{{HOMEPAGE_VAR_FLOOD_USERNAME}}";
                password = "{{HOMEPAGE_VAR_FLOOD_PASSWORD}}";
              };
            };
          }
          {
            Bazarr = {
              icon = "bazarr.png";
              href = "https://bazarr.${domain}";
              siteMonitor = "http://localhost:6767/ping/api/system/status?apikey={{HOMEPAGE_VAR_BAZARR_API_KEY}}";
              widget = {
                type = "bazarr";
                url = "http://localhost:6767";
                key = "{{HOMEPAGE_VAR_BAZARR_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        "System" = [
          {
            Scrutiny = {
              icon = "scrutiny.png";
              href = "https://scrutiny.${domain}";
              siteMonitor = "http://localhost:8181";
              widget = {
                type = "scrutiny";
                url = "http://localhost:8181";
              };
            };
          }
          {
            OPNSense = {
              icon = "opnsense.png";
              href = "{{HOMEPAGE_VAR_OPNSENSE_URL}}";
              widget = {
                type = "opnsense";
                url = "{{HOMEPAGE_VAR_OPNSENSE_URL}}";
                username = "{{HOMEPAGE_VAR_OPNSENSE_USERNAME}}";
                password = "{{HOMEPAGE_VAR_OPNSENSE_PASSWORD}}";
              };
            };
          }
          {
            Grafana = {
              icon = "grafana.png";
              href = "https://grafana.${domain}";
              siteMonitor = "http://localhost:2342";
              widget = {
                type = "grafana";
                url = "http://localhost:2342";
                username = "{{HOMEPAGE_VAR_GRAFANA_USERNAME}}";
                password = "{{HOMEPAGE_VAR_GRAFANA_PASSWORD}}";
              };
            };
          }
          {
            Unifi = {
              icon = "unifi.png";
              href = "https://unifi.${domain}";
              siteMonitor = "https://localhost:8443";
              widget = {
                type = "unifi";
                url = "https://localhost:8443";
                username = "{{HOMEPAGE_VAR_UNIFI_USERNAME}}";
                password = "{{HOMEPAGE_VAR_UNIFI_PASSWORD}}";
              };
            };
          }
        ];
      }
    ];
  };

  services.nginx.virtualHosts."${domain}" = {
    locations."/" = {
      proxyPass = "http://localhost:8082/";
    };
  };
}