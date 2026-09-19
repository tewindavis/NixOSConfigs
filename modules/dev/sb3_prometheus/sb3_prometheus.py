"""Export stable-baselines3 training stats to the local Prometheus.

Pass the callback to learn() and everything SB3's logger records
(rollout/ep_rew_mean, time/fps, train/loss, train/entropy_loss, ...) is
served on http://127.0.0.1:9435/metrics, which dl-prototype's Prometheus
scrapes every 5s and the Grafana "Training run" dashboard charts:

    from sb3_prometheus import PrometheusCallback
    model.learn(1_000_000, callback=PrometheusCallback(run="ppo-cartpole"))

Values update whenever SB3 dumps its log (every `log_interval`), plus the
timestep counter on every step. One training process per port; pass
port=... to run two at once (and add the port to Prometheus's scrape job).
"""

from numbers import Number

from prometheus_client import Gauge, start_http_server
from stable_baselines3.common.callbacks import BaseCallback
from stable_baselines3.common.logger import KVWriter

DEFAULT_PORT = 9435

# Every numeric logger key becomes one series, labelled with the key.
VALUE = Gauge("sb3_value", "Value logged by stable-baselines3", ["run", "key"])
TIMESTEPS = Gauge("sb3_timesteps", "Environment steps taken so far", ["run"])

# learn() is often called more than once in a process (resuming, curricula);
# the server must start only once per port.
_serving = set()


class PrometheusWriter(KVWriter):
    """SB3 logger output that sets a gauge for each numeric value."""

    def __init__(self, run):
        self.run = run

    def write(self, key_values, key_excluded, step=0):
        for key, value in key_values.items():
            if isinstance(value, Number) and not isinstance(value, bool):
                VALUE.labels(self.run, key).set(float(value))

    def close(self):
        pass


class PrometheusCallback(BaseCallback):
    """Starts the metrics server and adds PrometheusWriter to the logger."""

    def __init__(self, run="default", port=DEFAULT_PORT, verbose=0):
        super().__init__(verbose)
        self.run = run
        self.port = port

    def _on_training_start(self):
        # Loopback only: Prometheus runs on the same host, and Grafana is
        # reached through an SSH tunnel, so nothing needs this on the LAN.
        if self.port not in _serving:
            start_http_server(self.port, addr="127.0.0.1")
            _serving.add(self.port)
        formats = self.model.logger.output_formats
        if not any(isinstance(f, PrometheusWriter) and f.run == self.run for f in formats):
            formats.append(PrometheusWriter(self.run))

    def _on_step(self):
        TIMESTEPS.labels(self.run).set(self.num_timesteps)
        return True
