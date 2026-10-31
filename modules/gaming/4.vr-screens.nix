{ pkgs, config, ... }:

# ── VR screens — virtual Sway monitors for WayVR ───────────────────────────────
# Adds headless (virtual) outputs to the running Sway session, placed to the
# RIGHT of the physical monitors. WayVR shows each one as a panel in the
# headset; the mouse slides onto them past the right edge of the real screen,
# the keyboard follows focus, so apps there are driven by mouse + keyboard.
#
#   vr-screens on      → create N screens, bind workspaces 8, 9, … to them
#   vr-screens off     → remove them (their windows move back to the real monitor)
#   vr-screens toggle  /  vr-screens status
#
# Tunables (env): VR_SCREENS=2  VR_RES=1920x1080  VR_FIRST_WS=8
# Sway only — under i3/X11 the script refuses to run.
#
# Reads: config.profile.username
let
  user = config.profile.username;

  vr-screens = pkgs.writeShellApplication {
    name          = "vr-screens";
    runtimeInputs = with pkgs; [ sway jq coreutils ];
    text = ''
      if [ -z "''${SWAYSOCK:-}" ]; then
        echo "vr-screens: działa tylko w sesji Sway" >&2
        exit 1
      fi

      COUNT="''${VR_SCREENS:-2}"
      RES="''${VR_RES:-1920x1080}"
      FIRST_WS="''${VR_FIRST_WS:-8}"

      headless() {
        swaymsg -t get_outputs -r \
          | jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name'
      }

      right_edge() {
        swaymsg -t get_outputs -r \
          | jq '[.[] | select(.active) | .rect.x + .rect.width] | max // 0'
      }

      status() {
        swaymsg -t get_outputs -r \
          | jq -r '.[] | "\(.name)\t\(.rect.width)x\(.rect.height) @ \(.rect.x),\(.rect.y)\tws: \(.current_workspace)"'
      }

      on() {
        if [ -n "$(headless)" ]; then
          echo "vr-screens: już włączone"
          status
          return
        fi

        local prev x w i before name ws
        prev=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .name')
        x=$(right_edge)
        w=''${RES%x*}

        for ((i = 0; i < COUNT; i++)); do
          before=$(headless | sort)
          swaymsg create_output >/dev/null
          name=$(comm -13 <(echo "$before") <(headless | sort) | head -n1)

          swaymsg output "$name" mode "$RES" position "$x" 0 >/dev/null

          ws=$((FIRST_WS + i))
          swaymsg "workspace number $ws output $name" >/dev/null
          swaymsg "workspace number $ws; move workspace to output $name" >/dev/null

          echo "$name → workspace $ws"
          x=$((x + w))
        done

        swaymsg -- workspace "$prev" >/dev/null
      }

      off() {
        local o
        for o in $(headless); do
          swaymsg output "$o" unplug >/dev/null
          echo "usunięto $o"
        done
      }

      case "''${1:-toggle}" in
        on)     on ;;
        off)    off ;;
        status) status ;;
        toggle) if [ -n "$(headless)" ]; then off; else on; fi ;;
        *)      echo "użycie: vr-screens [on|off|toggle|status]" >&2; exit 1 ;;
      esac
    '';
  };
in
{
  home-manager.users.${user} = {
    home.packages = [ vr-screens ];
  };
}