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
      ctl() { ${pkgs.systemd}/bin/systemctl --user "$@"; }
      state_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/notify-failure"
    else
      ctl() { ${pkgs.systemd}/bin/systemctl "$@"; }
      state_dir=/run/notify-failure
    fi

    # A switch stops and restarts units, and a unit killed mid-run reports
    # `Failed with result 'signal'` and fires OnFailure even though it is
    # about to come straight back. That is what filled the screen with "unit
    # failed" after an update: the updater's own service, home-manager-td and
    # the switch unit, none of which were actually broken. So wait for the
    # dust to settle and only speak up if the unit is *still* failed. A unit
    # that systemd restarts successfully stays quiet; one that keeps failing
    # ends in the failed state and is reported as before.
    ${pkgs.coreutils}/bin/sleep 5
    ctl is-failed --quiet "$unit" || exit 0

    # A failed switch already reported itself in the terminal you ran it in;
    # a popup saying the same thing is pure duplication.
    case "$unit" in
      nixos-rebuild-switch-to-configuration.service) exit 0 ;;
    esac

    # One notification per unit per hour. fwupd-refresh runs every 90 minutes
    # and pulls in fwupd, so a daemon that can't start turns into a popup
    # every 90 minutes forever; the first one is news, the rest are noise.
    stamp="$state_dir/$unit"
    ${pkgs.coreutils}/bin/mkdir -p "$state_dir" 2>/dev/null || true
    if [ -f "$stamp" ]; then
      last=$(${pkgs.coreutils}/bin/cat "$stamp" 2>/dev/null || echo 0)
      now=$(${pkgs.coreutils}/bin/date +%s)
      [ $((now - last)) -lt 3600 ] && exit 0
    fi
    ${pkgs.coreutils}/bin/date +%s > "$stamp" 2>/dev/null || true

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
