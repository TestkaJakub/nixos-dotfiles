{ pkgs, config, ... }:

# ── Pomodoro ───────────────────────────────────────────────────────────────────
# Minimal custom pomodoro. State lives in $XDG_RUNTIME_DIR/pomodoro/:
#   end   — epoch second when the session ends
#   pid   — PID of the background sleep/notify process
#
# Binaries:
#   pomo-start   — start a new session (default 25 min)
#   pomo-add     — cancel current, restart with (remaining + 5) min
#   pomo-remove  — cancel current, restart with (remaining - 5) min
#   pomo-cancel  — cancel the session
#   pomo-waybar  — stdout JSON consumed by waybar's custom module
#
# Waybar config (desktop/bar.nix):
#   exec           = "pomo-waybar";
#   interval       = 1;
#   return-type    = "json";
#   on-click       = "pomo-start";
#   on-click-right = "pomo-cancel";
#   on-scroll-up   = "pomo-add";
#   on-scroll-down = "pomo-remove";
let
  user       = config.profile.username;
  jq         = "${pkgs.jq}/bin/jq";
  notify     = "${pkgs.libnotify}/bin/notify-send";
  defaultSecs = 25 * 60;
  adjustSecs  = 5 * 60;
  minSecs     = 60; # never go below 1 min

  # Shell snippet sourced by every pomo-* script
  common = ''
    STATE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pomodoro"
    mkdir -p "$STATE"

    _read()  { cat "$STATE/$1" 2>/dev/null || echo "''${2:-}"; }
    _write() { printf '%s' "$1" > "$STATE/$2"; }

    _remaining() {
      local end now
      end=$(_read end 0)
      now=$(date +%s)
      echo $(( end - now ))
    }

    _kill() {
      local pid
      pid=$(_read pid "")
      [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
      rm -f "$STATE/pid"
    }

    _start() {
      local secs=$1
      [ "$secs" -lt ${toString minSecs} ] && secs=${toString minSecs}
      local end
      end=$(( $(date +%s) + secs ))
      _write "$end" end
      (
        sleep "$secs"
        ${notify} -u normal -t 10000 "Pomodoro" "Session finished!"
        rm -f "$STATE/end" "$STATE/pid"
      ) &
      _write "$!" pid
    }
  '';

  pomoStart = pkgs.writeShellScriptBin "pomo-start" ''
    ${common}
    _kill
    rm -f "$STATE/end"
    _start ${toString defaultSecs}
    ${notify} -u low -t 3000 "Pomodoro" "Started — 25 min"
  '';

  pomoAdd = pkgs.writeShellScriptBin "pomo-add" ''
    ${common}
    rem=$(_remaining)
    [ "$rem" -le 0 ] && rem=${toString defaultSecs}
    new=$(( rem + ${toString adjustSecs} ))
    _kill
    _start "$new"
    mins=$(( new / 60 ))
    ${notify} -u low -t 3000 "Pomodoro" "+5 min — ''${mins} min remaining"
  '';

  pomoRemove = pkgs.writeShellScriptBin "pomo-remove" ''
    ${common}
    rem=$(_remaining)
    [ "$rem" -le 0 ] && rem=${toString defaultSecs}
    new=$(( rem - ${toString adjustSecs} ))
    [ "$new" -lt ${toString minSecs} ] && new=${toString minSecs}
    _kill
    _start "$new"
    mins=$(( new / 60 ))
    ${notify} -u low -t 3000 "Pomodoro" "-5 min — ''${mins} min remaining"
  '';

  pomoCancel = pkgs.writeShellScriptBin "pomo-cancel" ''
    ${common}
    _kill
    rm -f "$STATE/end"
    ${notify} -u low -t 3000 "Pomodoro" "Cancelled"
  '';

  pomoWaybar = pkgs.writeShellScriptBin "pomo-waybar" ''
    ${common}
    rem=$(_remaining)
    pid=$(_read pid "")

    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null || [ "$rem" -le 0 ]; then
      ${jq} -cn '{text: "pomo", tooltip: "idle — click to start 25 min", class: "idle"}'
      exit 0
    fi

    mins=$(( rem / 60 ))
    secs=$(( rem % 60 ))
    time=$(printf '%02d:%02d' "$mins" "$secs")

    ${jq} -cn \
      --arg text    "● $time" \
      --arg tooltip "Running — $time remaining (scroll to adjust)" \
      --arg class   "focus" \
      '{text: $text, tooltip: $tooltip, class: $class}'
  '';
in
{
  home-manager.users.${user}.home.packages = [
    pomoStart
    pomoAdd
    pomoRemove
    pomoCancel
    pomoWaybar
  ];
}
