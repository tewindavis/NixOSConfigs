{ pkgs, ... }:
let
  # Notification for a failed unit. $1 is the unit name, $2 the scope.
  #
  # Journal lines are untrusted text and swaync renders notification bodies as
  # Pango markup (see docs/security.md), so both the unit name and the log
  # tail are escaped here.
  notify-failure = pkgs.writeShellScript "notify-failure" ''
    unit="$1"
    scope="''${2:-system}"
    esc() { ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

    if [ "$scope" = user ]; then
      log=$(${pkgs.systemd}/bin/journalctl --user -u "$unit" -n 5 --no-pager -o cat 2>/dev/null)
    else
      log=$(${pkgs.systemd}/bin/journalctl -u "$unit" -n 5 --no-pager -o cat 2>/dev/null)
    fi
    title="Unit failed: $(printf '%s' "$unit" | esc)"
    body=$(printf '%s' "$log" | ${pkgs.coreutils}/bin/tail -c 400 | esc)

    if [ "$scope" = user ]; then
      # Already in the session: notify-send finds the bus in the environment.
      ${pkgs.libnotify}/bin/notify-send -u critical -a systemd "$title" "$body"
      exit 0
    fi

    # System scope has no session bus of its own, so hand the notification to
    # every logged-in user that has one. Before anyone logs in there is no
    # bus and nothing is sent, which is what keeps boot-time failures from
    # queueing up a burst of popups at login.
    for dir in /run/user/*; do
      [ -S "$dir/bus" ] || continue
      uid=''${dir##*/}
      user=$(${pkgs.coreutils}/bin/id -nu "$uid" 2>/dev/null) || continue
      ${pkgs.util-linux}/bin/runuser -u "$user" -- \
        env DBUS_SESSION_BUS_ADDRESS="unix:path=$dir/bus" \
        ${pkgs.libnotify}/bin/notify-send -u critical -a systemd "$title" "$body" \
        >/dev/null 2>&1 || true
    done
    exit 0
  '';

  # `OnFailure=` with no value resets the list inherited from the drop-in
  # below, so a handler that itself fails can't trigger another handler.
  handler = scope: {
    description = "Notify that %i failed";
    unitConfig.OnFailure = "";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${notify-failure} %i ${scope}";
    };
  };

  # A drop-in under <scope>/service.d/ applies to *every* service in that
  # scope, which is how this covers units that don't exist yet without
  # touching each one. Verified by making a unit fail and watching the
  # handler instance run.
  #
  # Shipped as a systemd.packages package rather than environment.etc:
  # /etc/systemd/system is already a directory in the etc tree and a new
  # subdirectory under it fails the etc build with "Permission denied".
  dropIns = pkgs.runCommand "onfailure-dropins" { } ''
    for scope in system user; do
      mkdir -p "$out/lib/systemd/$scope/service.d"
      cat > "$out/lib/systemd/$scope/service.d/50-onfailure.conf" <<EOF
    [Unit]
    OnFailure=notify-failure@%n.service
    EOF
    done
  '';
in
{
  # A unit failing used to be silent: syncthing, telegraf, the update-check
  # timer or a Home Manager service could die and nothing would say so until
  # something downstream broke. Every service in both scopes now points at a
  # handler that posts a critical notification (critical bypasses
  # do-not-disturb) naming the unit, with the last 5 journal lines.
  systemd.services."notify-failure@" = handler "system";
  systemd.user.services."notify-failure@" = handler "user";

  systemd.packages = [ dropIns ];
}
