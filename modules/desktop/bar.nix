{ pkgs, config, ... }:

# ── Waybar ─────────────────────────────────────────────────────────────────────
# Reads: config.theme.{palette, functions}
#        config.profile.username
let
  t    = config.theme;
  user = config.profile.username;

  lightenedPrimary  = t.functions.lighten t.palette.primary 0.1;
  waybarFocusedText = t.functions.textcolor lightenedPrimary;
  waybarText        = t.functions.textcolor t.palette.primary;
in
{
  home-manager.users.${user}.programs.waybar = {
    enable = true;

    style = ''
      window#waybar {
        background-color: ${t.palette.primary};
        font-family: "JetBrains Nerd Font", monospace;
        font-size: 12px;
        border: 1px solid ${t.palette.border};
      }
      .module {
        border: 1px solid ${t.palette.border};
        padding: 0 8px;
        margin-right: -1px;
        color: ${waybarText};
      }
      #workspaces { padding: 0; margin: 0; }
      #workspaces button {
        padding: 0 5px;
        margin: 0 1px;
        border-radius: 4px;
        background: transparent;
        min-height: 0;
        min-width: 0;
      }
      #workspaces button.active {
        background: ${lightenedPrimary};
        color: ${waybarFocusedText};
      }
      #workspaces button.urgent {
        background: ${waybarFocusedText};
        color: ${waybarFocusedText};
      }
    '';

    settings.main = {
      modules-left  = [ "ext/workspaces" ];
      modules-right = [ "custom/bluetooth" "custom/network" "custom/pamixer" "battery" "clock" ];

      clock = {
        interval       = 1;
        format         = "{:%d.%m.%Y %H:%M}";
        tooltip-format = "{:%A, %d %B %Y %H:%M:%S}";
      };

      battery = {
        interval        = 5;
        format          = "Pow: {}%";
        format-charging = "Pow: {}% charging";
      };

      "ext/workspaces" = {
        format         = "{icon}";
        ignore-hidden  = true;
        on-click       = "activate";
        on-click-right = "deactivate";
        sort-by-id     = true;
      };

      "custom/network" = {
        interval    = 5;
        format      = "{}";
        return-type = "json";
        on-click    = "alacritty -e nmtui";
        exec = let
          script = pkgs.writeShellApplication {
            name          = "waybar-network";
            runtimeInputs = with pkgs; [ iw wirelesstools gnugrep iproute2 coreutils ];
            checkPhase    = "";
            text = ''
              ssid=$(iwgetid -r)
              if ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; then
                [ -z "$ssid" ] && ssid="Ethernet"
                echo "{\"text\": \"Net: $ssid\", \"tooltip\": \"Connected: $ssid\"}"
              else
                echo '{"text": "No connection", "tooltip": "No internet connection"}'
              fi
            '';
          };
        in "${script}/bin/waybar-network";
      };

      "custom/bluetooth" = {
        interval    = 8;
        format      = "{}";
        return-type = "json";
        on-click    = "blueman-manager";
        exec = let
          script = pkgs.writeShellApplication {
            name          = "waybar-bluetooth";
            runtimeInputs = with pkgs; [ bluez gnugrep gawk coreutils ];
            checkPhase    = "";
            text = ''
              if bluetoothctl --help | grep -q "connected-devices"; then
                devices_raw=$(bluetoothctl connected-devices)
              else
                devices_raw=$(bluetoothctl devices Connected)
              fi

              if [ -z "$devices_raw" ]; then
                echo '{"text": "BT none", "tooltip": "No Bluetooth devices connected"}'
                exit 0
              fi

              display_text=""
              tooltip="Connected Bluetooth devices:\n"
              tmpfile=$(mktemp)
              echo "$devices_raw" > "$tmpfile"

              while read -r _ mac rest; do
                [ -z "$mac" ] && continue
                name=$(echo "$rest" | sed 's/^[[:space:]]*//')
                battery=$(bluetoothctl info "$mac" 2>/dev/null \
                  | grep "Battery Percentage" | grep -o "[0-9]\+%" || true)
                entry="$name''${battery:+ ($battery)}"
                tooltip="$tooltip$entry\n"
                display_text="''${display_text:+$display_text, }$entry"
              done < "$tmpfile"
              rm -f "$tmpfile"

              [ -z "$display_text" ] && display_text="unknown"
              echo "{\"text\": \"BT $display_text\", \"tooltip\": \"$tooltip\"}"
            '';
          };
        in "${script}/bin/waybar-bluetooth";
      };

      "custom/pamixer" = {
        interval       = 1;
        format         = "{}";
        return-type    = "json";
        on-click       = "pamixer -t";
        on-scroll-up   = "pamixer -i 5";
        on-scroll-down = "pamixer -d 5";
        exec = let
          script = pkgs.writeShellApplication {
            name          = "waybar-volume";
            runtimeInputs = [ pkgs.pamixer ];
            checkPhase    = "";
            text = ''
              volume=$(pamixer --get-volume)
              muted=$(pamixer --get-mute)
              if [ "$muted" = "true" ]; then
                echo '{"text": "Muted", "tooltip": "Muted"}'
              else
                echo "{\"text\": \"Vol: $volume%\", \"tooltip\": \"Vol: $volume%\"}"
              fi
            '';
          };
        in "${script}/bin/waybar-volume";
      };
    };
  };
}
