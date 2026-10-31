{ pkgs, config, ... }:

# ── VR screens — on-demand virtual monitors for WayVR (i3 / X11) ───────────────
# X11 can't create outputs out of thin air, so this fakes one:
#
#   1. Kernel: the unused DP-1 port is forced "connected" with a fake 3840x2160
#      EDID. To Xorg it looks like a real monitor plugged in (the "canvas").
#   2. vr-screens: the canvas is switched on only while needed and carved into
#      up to four 1920x1080 RandR monitors (VR1..VR4, 2x2 grid) with
#      `xrandr --setmonitor`. i3 treats each as its own output with its own
#      workspace; the mouse reaches them because the GPU really scans the
#      canvas out.
#
#   HDMI-2 (real)   │ VR1 │ VR2 │      ← canvas sits right of the real screen
#                   │ VR3 │ VR4 │
#
#   vr-screens on [N]   → canvas on + N screens (default 2)
#   vr-screens add      → one more screen (max 4)
#   vr-screens del      → remove the last screen (canvas off when none left)
#   vr-screens off      → remove all, canvas off
#   vr-screens toggle  /  vr-screens status
#
# Workspaces: VR1 → 6, VR2 → 7, VR3 → 8, VR4 → 9   (env VR_FIRST_WS)
# Needs a reboot after the first nrs (kernel parameters).
#
# Reads: config.profile.username
let
  user = config.profile.username;

  canvasPort = "DP-1";   # kernel connector name (card1-DP-1) — also the Xorg name here
  mainOutput = "HDMI-2"; # the real monitor

  vr-screens = pkgs.writeShellApplication {
    name          = "vr-screens";
    runtimeInputs = with pkgs; [ xrandr i3 jq gawk gnugrep gnused coreutils ];
    text = ''
      OUT="''${VR_OUTPUT:-${canvasPort}}"
      MAIN="''${VR_MAIN:-${mainOutput}}"
      FIRST_WS="''${VR_FIRST_WS:-6}"
      SW=1920 SH=1080 MAX=4

      vr_list() {
        xrandr --listmonitors | awk 'NR > 1 { gsub(/[+*]/, "", $2); print $2 }' \
          | grep -E '^VR[0-9]+$' | sort -V || true
      }

      # x offset where the canvas starts = right edge of the real monitor
      canvas_x() {
        xrandr --query \
          | sed -n "s/^$MAIN connected.* \([0-9]*\)x[0-9]*+\([0-9]*\)+[0-9]*.*/\1 \2/p" \
          | awk '{ print $1 + $2 }'
      }

      refresh_i3() {
        i3-msg restart >/dev/null 2>&1 || true
        sleep 1
        until i3-msg -t get_version >/dev/null 2>&1; do sleep 0.2; done
      }

      assign_workspaces() {
        local prev m k ws
        prev=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
        for m in $(vr_list); do
          k=''${m#VR}
          ws=$((FIRST_WS + k - 1))
          i3-msg "workspace number $ws; move workspace to output $m" >/dev/null
          echo "$m → workspace $ws"
        done
        i3-msg "workspace $prev" >/dev/null
      }

      # adds one RandR monitor, no i3 refresh
      add_one() {
        local n k bx x y target
        n=$(vr_list | wc -l)
        if [ "$n" -ge "$MAX" ]; then
          echo "vr-screens: maksymalnie $MAX ekrany" >&2
          return 1
        fi
        if [ "$n" -eq 0 ]; then
          xrandr --output "$OUT" --mode 3840x2160 --right-of "$MAIN"
          xrandr --output "$MAIN" --primary
        fi
        k=$((n + 1))
        bx=$(canvas_x)
        x=$((bx + ((k - 1) % 2) * SW))
        y=$((((k - 1) / 2) * SH))
        # the first monitor claims the output; the rest are "none"
        if [ "$k" -eq 1 ]; then target="$OUT"; else target=none; fi
        xrandr --setmonitor "VR$k" "$SW/527x$SH/296+$x+$y" "$target"
      }

      remove_all() {
        local m changed=0
        for m in $(vr_list | sort -rV); do
          xrandr --delmonitor "$m"
          changed=1
        done
        xrandr --output "$OUT" --off
        xrandr --output "$MAIN" --primary
        return $((1 - changed))
      }

      on() {
        local count="''${1:-2}" i
        remove_all || true
        for ((i = 0; i < count; i++)); do add_one || break; done
        refresh_i3
        assign_workspaces
      }

      add() {
        add_one
        refresh_i3
        assign_workspaces
      }

      del() {
        local last
        last=$(vr_list | tail -n1)
        if [ -z "$last" ]; then echo "vr-screens: brak ekranów"; return; fi
        xrandr --delmonitor "$last"
        if [ -z "$(vr_list)" ]; then xrandr --output "$OUT" --off; fi
        refresh_i3
        echo "usunięto $last"
      }

      off() {
        if remove_all; then refresh_i3; fi
        echo "vr-screens: wyłączone"
      }

      case "''${1:-toggle}" in
        on)     on "''${2:-2}" ;;
        add)    add ;;
        del)    del ;;
        off)    off ;;
        status) xrandr --listmonitors ;;
        toggle) if [ -n "$(vr_list)" ]; then off; else on; fi ;;
        *)      echo "użycie: vr-screens [on [N]|add|del|off|toggle|status]" >&2; exit 1 ;;
      esac
    '';
  };
in
{
  # ── Fake monitor on the free DP-1 port ──────────────────────────────────────
  # 3840x2160@60, CVT reduced blanking. Becomes edid/vrcanvas.bin and the
  # kernel parameters video=DP-1:e drm.edid_firmware=DP-1:edid/vrcanvas.bin
  hardware.display = {
    edid.modelines."vrcanvas" = "533.25  3840 3888 3920 4000  2160 2163 2168 2222  +hsync -vsync";
    outputs.${canvasPort} = {
      edid = "vrcanvas.bin";
      mode = "e";   # force "connected" even with nothing plugged in
    };
  };

  home-manager.users.${user} = {
    home.packages = [ vr-screens ];
  };
}