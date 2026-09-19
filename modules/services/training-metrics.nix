# dl-prototype: system and GPU metrics for watching training runs from other
# machines. Exporters listen on 127.0.0.1 and are scraped by the local
# Prometheus in monitoring.nix; view the dashboards over the SSH tunnel
# described there.
{ config, pkgs, ... }:

let
  exporters = config.services.prometheus.exporters;

  dashboards = pkgs.linkFarm "training-dashboards" [
    {
      # The exporter's own dashboard, written for Grafana's import dialog:
      # it names its data source ${DS_PROMETHEUS}, which only the dialog
      # fills in. Point it at monitoring.nix's fixed uid instead.
      name = "nvidia-gpu.json";
      path = pkgs.runCommand "nvidia-gpu-dashboard.json" { } ''
        sed 's/''${DS_PROMETHEUS}/prometheus/g' \
          ${pkgs.prometheus-nvidia-gpu-exporter.src}/docs/grafana/dashboard.json > $out
      '';
    }
    {
      # grafana.com "Node Exporter Full" (id 1860), pinned by revision and
      # hash. Its ${ds_prometheus} is a data-source picker variable, which
      # works as provisioned.
      name = "node-exporter-full.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/45/download";
        name = "node-exporter-full.json";
        sha256 = "11hrll7fm626ikbva5md4gm0rca537vp4xsxa9sxl1pk15s6nk0q";
      };
    }
  ];
in
{
  imports = [ ./monitoring.nix ];

  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        listenAddress = "127.0.0.1";
        enabledCollectors = [ "systemd" ];
      };
      # CPU/RAM are node's; this adds utilization, memory, temperature,
      # power and clocks per GPU, read through nvidia-smi.
      nvidia-gpu = {
        enable = true;
        listenAddress = "127.0.0.1";
      };
    };
    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "5s";
        static_configs = [ { targets = [ "127.0.0.1:${toString exporters.node.port}" ]; } ];
      }
      {
        job_name = "nvidia-gpu";
        scrape_interval = "5s";
        static_configs = [ { targets = [ "127.0.0.1:${toString exporters.nvidia-gpu.port}" ]; } ];
      }
    ];
  };

  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "training";
      folder = "Training";
      options.path = dashboards;
    }
  ];
}
