{ pkgs, config, ... }:

# ── VR screens — on-demand virtual monitors for WayVR (i3 / X11) ───────────────
# X11 can't create outputs out of thin air, so this fakes one:
#
#   1. Kernel: the unused DP-1 port gets a fake 3840x2160 EDID. It stays
#      "disconnected" at boot (forcing it at boot made the session unusable:
#      i3 put the bar and workspace 1 on the invisible screen).
#   2. vr-screens: forces DP-1 "connected" at runtime (sysfs, via a tiny root
#      helper allowed in sudo), so to Xorg a monitor gets plugged in — the
#      "canvas". It is switched on only while needed and carved into
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
# Needs a reboot after the first nrs (kernel parameter drm.edid_firmware).
# A reboot always returns DP-1 to "disconnected".
#
# Reads: config.profile.username
let
  user = config.profile.username;

  canvasPort = "DP-1";   # kernel connector name (card1-DP-1) — also the Xorg name here
  mainOutput = "HDMI-2"; # the real monitor

  # Root helper: plug / unplug the fake monitor. The only thing sudo allows.
  vr-canvas = pkgs.writeShellScript "vr-canvas" ''
    case "''${1:-}" in
      on)  state=on ;;
      off) state=detect ;;
      *)   echo "usage: vr-canvas on|off" >&2; exit 1 ;;
    esac
    for f in /sys/class/drm/card*-${canvasPort}/status; do
      echo "$state" > "$f"
    done
  '';

  vr-screens = pkgs.writeShellApplication {
    name          = "vr-screens";
    runtimeInputs = with pkgs; [ xrandr i3 jq gawk gnugrep gnused coreutils ];
    text = ''
      OUT="''${VR_OUTPUT:-${canvasPort}}"
      MAIN="''${VR_MAIN:-${mainOutput}}"
      FIRST_WS="''${VR_FIRST_WS:-6}"
      SW=1920 SH=1080 MAX=4
      SUDO=/run/wrappers/bin/sudo

      canvas_plug()   { "$SUDO" -n ${vr-canvas} on; }
      canvas_unplug() { "$SUDO" -n ${vr-canvas} off; }

      # wait until Xorg sees the fake monitor with its 4K mode
      wait_for_canvas() {
        local i
        for ((i = 0; i < 50; i++)); do
          if xrandr --query | awk -v o="$OUT" '
               $1 == o { f = 1; next }
               /^[^ ]/ { f = 0 }
               f && $1 == "3840x2160" { found = 1 }
               END { exit !found }'; then
            return 0
          fi
          sleep 0.1
        done
        echo "vr-screens: $OUT nie pojawił się z trybem 3840x2160" >&2
        canvas_unplug
        return 1
      }

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
          canvas_plug
          wait_for_canvas || return 1
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
        canvas_unplug
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
        if [ -z "$(vr_list)" ]; then
          xrandr --output "$OUT" --off
          canvas_unplug
        fi
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
  # kernel parameter drm.edid_firmware=DP-1:edid/vrcanvas.bin.
  # NO `mode = "e"`: the port must stay disconnected at boot.
  hardware.display = {
    edid.modelines."vrcanvas" = "533.25  3840 3888 3920 4000  2160 2163 2168 2222  +hsync -vsync";
    outputs.${canvasPort}.edid = "vrcanvas.bin";
  };

  security.sudo.extraRules = [{
    users    = [ user ];
    commands = [{ command = "${vr-canvas}"; options = [ "NOPASSWD" ]; }];
  }];

  home-manager.users.${user} = {
    home.packages = [ vr-screens ];

    # ── WayVR panel: buttons for vr-screens, toggled from the watch ────────────
    # A custom panel shows up on the watch as a "panel" button next to the
    # screens. WayVR on X11 lists RandR monitors only at startup, so after
    # + / − / OFF press ↻ (restarts WayVR) to get the new VR1..VR4 panels.
    # Absolute store path: WayVR started by WiVRn doesn't see the user PATH.
    xdg.configFile."wayvr/conf.d/vr-screens.yaml".text = ''
      custom_panels:
        - "vrscreens"
    '';

    xdg.configFile."wayvr/theme/gui/vrscreens.xml".text = let
      run = cmd: "::ShellExec ${vr-screens}/bin/vr-screens ${cmd} &gt;/dev/null 2&gt;&amp;1";
    in ''
      <layout version="2">
        <macro name="btn" border="2" round="6" align_items="center" justify_content="center"
          padding="6" width="72" height="72" />

        <elements>
          <rectangle color="background" border_color="outline" round="10" border="2"
            padding="10" gap="8" flex_direction="row" align_items="center">
            <Button macro="btn" tooltip_str="Dodaj ekran" _press="${run "add"}">
              <label text="+" size="32" weight="bold" color="on_background" />
            </Button>
            <Button macro="btn" tooltip_str="Usuń ostatni ekran" _press="${run "del"}">
              <label text="−" size="32" weight="bold" color="on_background" />
            </Button>
            <Button macro="btn" tooltip_str="Wyłącz wszystkie" _press="${run "off"}">
              <label text="OFF" size="20" weight="bold" color="on_background" />
            </Button>
            <rectangle width="2" height="72" color="outline" />
            <Button macro="btn" tooltip_str="Restart WayVR (odśwież listę ekranów)" _press="::Restart">
              <label text="↻" size="32" weight="bold" color="on_background" />
            </Button>
          </rectangle>
        </elements>
      </layout>
    '';
  };
}