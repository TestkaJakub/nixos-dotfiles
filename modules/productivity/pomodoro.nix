{ pkgs, config, ... }:

# ── Pomodoro ───────────────────────────────────────────────────────────────────
# Waybar custom module + notify-send timer. No GUI app.
#
# State lives under /run/user/<uid>/pomodoro/ (wiped on reboot):
#   pid      — PID of the running countdown process
#   end      — epoch second when the current session ends
#   mode     — "focus" | "short" | "long"
#   session  — current session number (1-based, resets after a long break)
#
# Binaries exposed:
#   pomo        — start / pause / skip / status
#   pomo-waybar — stdout JSON consumed by waybar's custom module
#
# Add to desktop/bar.nix manually:
#
#   modules-right = [ "custom/pomodoro" "custom/bluetooth" ... ];
#
#   "custom/pomodoro" = {
#     exec            = "${pkgs.pomo-waybar}/bin/pomo-waybar";  # use the store path from home.packages
#     interval        = 1;
#     format          = "{}";
#     return-type     = "json";
#     on-click        = "${pkgs.pomo}/bin/pomo toggle";
#     on-click-right  = "${pkgs.pomo}/bin/pomo skip";
#     on-click-middle = "${pkgs.pomo}/bin/pomo reset";
#     tooltip         = true;
#   };
#
#   CSS classes for styling: focus / short / long / paused / idle
#   e.g. in bar.nix style: "#custom-pomodoro.focus { color: ${t.palette.termAccent}; }"
#
# Durations (seconds) — edit the three variables below to taste.
let
  user = config.profile.username;

  focusSecs = 25 * 60;
  shortSecs  =  5 * 60;
  longSecs   = 15 * 60;
  setSize    = 4;

  notifySend = "${pkgs.libnotify}/bin/notify-send";
  jq         = "${pkgs.jq}/bin/jq";

  # ── pomo: main control binary ──────────────────────────────────────────────
  pomo = pkgs.writeShellScriptBin "pomo" ''
    STATE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pomodoro"
    mkdir -p "$STATE"

    _read()  { cat "$STATE/$1" 2>/dev/null || echo "''${2:-}"; }
    _write() { echo "$1" > "$STATE/$2"; }
    _kill()  {
      local pid
      pid=$(_read pid)
      [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
      rm -f "$STATE/pid"
    }

    _remaining() {
      local end now
      end=$(_read end 0)
      now=$(date +%s)
      echo $(( end - now ))
    }

    _fmt() {
      local s=$1
      [ "$s" -lt 0 ] && s=0
      printf '%02d:%02d' $(( s / 60 )) $(( s % 60 ))
    }

    _notify() {
      ${notifySend} -u normal -t 8000 "Pomodoro" "$1"
    }

    _start_countdown() {
      local secs=$1 mode=$2 label=$3
      local end
      end=$(( $(date +%s) + secs ))
      _write "$end"  end
      _write "$mode" mode
      (
        sleep "$secs"
        _notify "$label"
        local sess
        sess=$(_read session 1)
        if [ "$mode" = "focus" ]; then
          sess=$(( sess + 1 ))
          _write "$sess" session
          if [ "$sess" -gt ${toString setSize} ]; then
            _write 1 session
            _write "long" mode
            _write "$(( $(date +%s) + ${toString longSecs} ))" end
            _notify "Long break — ${toString (longSecs / 60)} min. Well done!"
            sleep ${toString longSecs}
            _notify "Back to work!"
            _write 1 session
            _write "focus" mode
            _write "$(( $(date +%s) + ${toString focusSecs} ))" end
          else
            _write "short" mode
            _write "$(( $(date +%s) + ${toString shortSecs} ))" end
            _notify "Short break — ${toString (shortSecs / 60)} min."
            sleep ${toString shortSecs}
            _notify "Focus time — session $(_read session 1) of ${toString setSize}"
            _write "focus" mode
            _write "$(( $(date +%s) + ${toString focusSecs} ))" end
          fi
        fi
      ) &
      _write "$!" pid
    }

    cmd="''${1:-help}"

    case "$cmd" in
      start|toggle)
        pid=$(_read pid)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          rem=$(_remaining)
          _kill
          _write "$rem" paused
          _notify "Paused — $(_fmt $rem) remaining"
        else
          rem=$(_read paused)
          mode=$(_read mode focus)
          if [ -n "$rem" ] && [ "$rem" -gt 0 ]; then
            rm -f "$STATE/paused"
            end=$(( $(date +%s) + rem ))
            _write "$end" end
            (
              sleep "$rem"
              _notify "Session complete!"
            ) &
            _write "$!" pid
            _notify "Resumed — $(_fmt $rem) remaining"
          else
            rm -f "$STATE"/*
            _write 1 session
            _start_countdown ${toString focusSecs} focus \
              "Focus session 1 of ${toString setSize} complete!"
            _notify "Focus — ${toString (focusSecs / 60)} min. session started"
          fi
        fi
        ;;
      skip)
        _kill
        rm -f "$STATE/paused"
        mode=$(_read mode focus)
        sess=$(_read session 1)
        if [ "$mode" = "focus" ]; then
          _notify "Skipped focus — short break"
          _write "short" mode
          _start_countdown ${toString shortSecs} short "Short break over!"
        else
          _notify "Skipped break — focus"
          _write "focus" mode
          _start_countdown ${toString focusSecs} focus \
            "Focus session $sess of ${toString setSize} complete!"
        fi
        ;;
      reset)
        _kill
        rm -f "$STATE"/*
        _notify "Pomodoro reset"
        ;;
      status)
        pid=$(_read pid)
        mode=$(_read mode focus)
        sess=$(_read session 1)
        rem=$(_remaining)
        paused=$(_read paused)
        if [ -n "$paused" ]; then
          echo "paused  $mode  session $sess  $(_fmt $paused) left"
        elif [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          echo "running  $mode  session $sess  $(_fmt $rem) left"
        else
          echo "idle"
        fi
        ;;
      help|*)
        echo "Usage: pomo <start|toggle|skip|reset|status>"
        ;;
    esac
  '';

  # ── pomo-waybar: JSON for waybar custom module ─────────────────────────────
  pomoWaybar = pkgs.writeShellScriptBin "pomo-waybar" ''
    STATE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pomodoro"

    _read() { cat "$STATE/$1" 2>/dev/null || echo "''${2:-}"; }

    _fmt() {
      local s=$1
      [ "$s" -lt 0 ] && s=0
      printf '%02d:%02d' $(( s / 60 )) $(( s % 60 ))
    }

    pid=$(_read pid)
    mode=$(_read mode focus)
    sess=$(_read session 1)
    end=$(_read end 0)
    now=$(date +%s)
    rem=$(( end - now ))
    paused=$(_read paused)

    if [ -n "$paused" ] && [ "$paused" -gt 0 ]; then
      text="⏸ $(_fmt $paused)"
      tooltip="Paused · $mode · session $sess/${toString setSize}"
      css="paused"
    elif [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      case "$mode" in
        focus) icon="●" ;;
        short) icon="○" ;;
        long)  icon="◎" ;;
        *)     icon="●" ;;
      esac
      text="$icon $(_fmt $rem)"
      tooltip="$mode · session $sess/${toString setSize} · $(_fmt $rem) left"
      css="$mode"
    else
      text="pomo"
      tooltip="idle — click to start"
      css="idle"
    fi

    ${jq} -cn \
      --arg text    "$text" \
      --arg tooltip "$tooltip" \
      --arg class   "$css" \
      '{text: $text, tooltip: $tooltip, class: $class}'
  '';

in
{
  home-manager.users.${user}.home.packages = [ pomo pomoWaybar ];
}
