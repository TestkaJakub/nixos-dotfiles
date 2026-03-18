{ pkgs, config, ... }:

# ── Pomodoro ───────────────────────────────────────────────────────────────────
# Uses pkgs.openpomodoro-cli — a Go CLI that is in nixpkgs 25.05.
# The binary is called `pomodoro` (not `openpomodoro-cli`).
#
# Waybar integration (desktop/bar.nix):
#   exec            = "pomo-waybar";
#   on-click        = "pomodoro start";
#   on-click-right  = "pomodoro finish";
#   on-click-middle = "pomodoro cancel";
#
# Usage:
#   pomodoro start                → start a 25-min pomodoro
#   pomodoro start --duration 25  → explicit duration in minutes
#   pomodoro start "task name"    → with description
#   pomodoro status               → show remaining time
#   pomodoro finish               → mark done early
#   pomodoro cancel               → cancel without recording
#   pomodoro history              → list past pomodoros
#
# State lives in ~/.local/share/openpomodoro (XDG). No daemon needed.
let
  user = config.profile.username;
  jq   = "${pkgs.jq}/bin/jq";

  # pomo-waybar: JSON wrapper for the Waybar custom module.
  # `pomodoro status` output:
  #   active:   "12:34 🍅"
  #   finished: "❗🍅"
  #   idle:     empty / non-zero exit
  pomoWaybar = pkgs.writeShellScriptBin "pomo-waybar" ''
    status=$(${pkgs.openpomodoro-cli}/bin/pomodoro status 2>/dev/null || true)

    if [ -z "$status" ]; then
      ${jq} -cn '{text: "pomo", tooltip: "idle — click to start", class: "idle"}'
      exit 0
    fi

    # Finished pomodoro shows the warning emoji but no MM:SS
    if ! echo "$status" | grep -qP '\d+:\d+'; then
      ${jq} -cn '{text: "✓ pomo", tooltip: "Pomodoro finished — click to start another", class: "focus"}'
      exit 0
    fi

    time=$(echo "$status" | grep -oP '\d+:\d+' | head -1 || echo "--:--")

    ${jq} -cn \
      --arg text    "● $time" \
      --arg tooltip "Pomodoro running — $time remaining" \
      --arg class   "focus" \
      '{text: $text, tooltip: $tooltip, class: $class}'
  '';
in
{
  home-manager.users.${user}.home.packages = [
    pkgs.openpomodoro-cli
    pomoWaybar
  ];
}
