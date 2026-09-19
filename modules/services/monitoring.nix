# Local-only Prometheus + Grafana. Both listen on 127.0.0.1, so this opens
# no firewall ports; view Grafana from another machine through SSH:
#
#   ssh -N -L 3000:localhost:3000 <host>    then http://localhost:3000
#
# (`grafana-tunnel <host>` in users/td/home.nix wraps that.) Log in as
# `admin`; the password is generated on the host at first start:
#
#   sudo cat /var/lib/grafana-secrets/admin_password
#
# Imported by training-metrics.nix and liftoff-telemetry.nix, which add
# scrape targets, pushed metrics and dashboards on top.
{ config, pkgs, ... }:

let
  secretsDir = "/var/lib/grafana-secrets";
in
{
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    retentionTime = "30d";
    # liftoff-telemetry.nix's Telegraf pushes samples here rather than
    # being scraped (telemetry arrives far faster than a scrape interval).
    extraFlags = [ "--web.enable-remote-write-receiver" ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
      };
      # Generated on the host by grafana-secrets below, so they never enter
      # the repo or the Nix store. These hosts aren't sops recipients.
      security = {
        admin_user = "admin";
        admin_password = "$__file{${secretsDir}/admin_password}";
        secret_key = "$__file{${secretsDir}/secret_key}";
      };
      # No phoning home: usage stats, update checks and the news feed.
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
        check_for_plugin_updates = false;
        feedback_links_enabled = false;
      };
      news.news_feed_enabled = false;
      # Default floor is 5s; the Liftoff dashboard refreshes every second.
      dashboards.min_refresh_interval = "1s";
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          # Fixed uid so provisioned dashboards can refer to it.
          uid = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
    };
  };

  systemd.services.grafana-secrets = {
    description = "Generate Grafana's admin password and secret key";
    wantedBy = [ "grafana.service" ];
    before = [ "grafana.service" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.coreutils ];
    script = ''
      install -d -m 0700 -o grafana -g grafana ${secretsDir}
      for name in admin_password secret_key; do
        f=${secretsDir}/$name
        if [ ! -s "$f" ]; then
          (umask 077; head -c 32 /dev/urandom | base64 | tr -d '/+=' > "$f")
          chown grafana:grafana "$f"
        fi
      done
    '';
  };
}
