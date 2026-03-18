{ pkgs, config, ... }:

# ── Pomodoro ───────────────────────────────────────────────────────────────────
# Uses the nixpkgs `pomo` CLI package (github.com/kevinschoon/pomo) instead of
# a custom shell script.
#
# Waybar integration (desktop/bar.nix):
#
#   "custom/pomodoro" = {
#     exec            = "pomo-waybar";
#     interval        = 1;
#     format          = "{}";
#     return-type     = "json";
#     on-click        = "pomo start";
#     on-click-right  = "pomo pause";
#     on-click-middle = "pomo delete 0";
#     tooltip         = true;
#   };
#
#   CSS classes: focus / paused / idle
#
# Usage:
#   pomo create -d 25m -s 5m 4 "Work"   → create a 4-session pomodoro
#   pomo start                           → start the first task
#   pomo pause                           → pause/resume
#   pomo delete 0                        → remove task at index 0 (reset)
#   pomo list                            → show all tasks
#   pomo show                            → show current status
let
  user = config.profile.username;
  jq   = "${pkgs.jq}/bin/jq";

  # ── pomo-waybar: thin JSON wrapper for waybar ─────────────────────────────
  # `pomo show` outputs a single line like:
  #   ● [1/4] Work 24:13 remaining
  # or nothing when idle.
  pomoWaybar = pkgs.writeShellScriptBin "pomo-waybar" ''
    status=$(${pkgs.pomo}/bin/pomo show 2>/dev/null || true)

    if [ -z "$status" ]; then
      ${jq} -cn '{text: "pomo", tooltip: "idle — click to start", class: "idle"}'
      exit 0
    fi

    # Detect paused state (pomo show prefixes with ◌ when paused)
    if echo "$status" | grep -q "◌"; then
      css="paused"
      icon="⏸"
    else
      css="focus"
      icon="●"
    fi

    # Extract remaining time — last field before "remaining"
    time=$(echo "$status" | grep -oP '\d+:\d+(?= remaining)' || echo "--:--")
    tooltip=$(echo "$status" | sed 's/^[[:space:]]*//')

    ${jq} -cn \
      --arg text    "$icon $time" \
      --arg tooltip "$tooltip" \
      --arg class   "$css" \
      '{text: $text, tooltip: $tooltip, class: $class}'
  '';
in
{
  home-manager.users.${user}.home.packages = [
    pkgs.pomo
    pomoWaybar
  ];
}
