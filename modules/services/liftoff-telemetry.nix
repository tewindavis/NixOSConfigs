# Liftoff (FPV drone sim) telemetry: the game streams UDP packets of 4-byte
# floats, Telegraf decodes them and pushes them into the local Prometheus
# (monitoring.nix) via remote write, and a provisioned dashboard charts
# them. View it over the SSH tunnel described in monitoring.nix.
#
# Enable it in the game by copying liftoff/TelemetryConfiguration.json to
# (macOS) ~/Library/Application Support/LuGus Studios/Liftoff/, with
# HOST_IP replaced by this host's address. Liftoff rereads it on every
# drone reset. Its StreamFormat order must match `entries` below exactly:
# the packets carry no field names, only values in that order.
#
# Format: https://steamcommunity.com/sharedfiles/filedetails/?id=3160488434
# The guide doesn't state byte order; Unity writes little-endian.
{ config, ... }:

let
  port = 9001;
  float = name: {
    inherit name;
    type = "float32";
  };
  # Timestamp, Position, Attitude, Velocity, Gyro, Input, Battery:
  # 20 floats, 80 bytes. MotorRPM is left out of the StreamFormat because
  # its length varies (a motor-count byte, then one float per motor).
  entries = map float [
    "timestamp"
    "position_x"
    "position_y"
    "position_z"
    "attitude_x"
    "attitude_y"
    "attitude_z"
    "attitude_w"
    "velocity_x"
    "velocity_y"
    "velocity_z"
    "gyro_pitch"
    "gyro_roll"
    "gyro_yaw"
    "input_throttle"
    "input_yaw"
    "input_pitch"
    "input_roll"
    "battery_voltage"
    "battery_percentage"
  ];
in
{
  imports = [ ./monitoring.nix ];

  services.telegraf = {
    enable = true;
    extraConfig = {
      agent = {
        interval = "1s";
        flush_interval = "1s";
      };
      inputs.socket_listener = [
        {
          service_address = "udp://:${toString port}";
          data_format = "binary";
          endianness = "le";
          binary = [
            {
              metric_name = "liftoff";
              inherit entries;
              # Anything that isn't a whole 80-byte packet is dropped.
              filter.length = 4 * builtins.length entries;
            }
          ];
        }
      ];
      # Prometheus remote write: metrics arrive as liftoff_<field>.
      outputs.http = [
        {
          url = "http://127.0.0.1:${toString config.services.prometheus.port}/api/v1/write";
          data_format = "prometheusremotewrite";
          headers = {
            "Content-Type" = "application/x-protobuf";
            "Content-Encoding" = "snappy";
            "X-Prometheus-Remote-Write-Version" = "0.1.0";
          };
        }
      ];
    };
  };

  # The game (on the Mac, or another machine) sends to this port. It's
  # the only port the monitoring setup opens; see docs/security.md.
  networking.firewall.allowedUDPPorts = [ port ];

  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "liftoff";
      folder = "Liftoff";
      options.path = ./liftoff/dashboards;
    }
  ];
}
