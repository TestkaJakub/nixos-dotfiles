{ config, pkgs, theme, ... }:
let
  lightenedPrimary = theme.functions.lighten theme.palette.primary 0.1;
  waybarText = theme.functions.complement theme.palette.primary;
in
{
  programs.waybar = {
    enable = true;
    style = ''
      window#waybar {
        background-color: ${theme.palette.primary};
	font-family: "JetBrains Nerd Font", monospace;
	font-size: 12px;
	border: 1px solid ${theme.palette.border};
      }
      .module {
        border: 1px solid ${theme.palette.border};
	padding: 0 8px;
	margin-right: -1px;
      }
      #workspaces {
	padding: 0;
        margin: 0;
      }

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
        color: ${waybarText};
      }

      #workspaces button.urgent {
        background: ${theme.palette.waybarUrgent};
        color: ${theme.palette.waybarUrgentText};
      }
    '';
    settings = {
      main = {
        modules-left = [ "ext/workspaces" ];
        modules-right = [ "custom/bluetooth" "custom/network" "custom/pamixer" "battery" "clock" ];
	clock = {
	  interval = 1;
	  format = "{:%d.%m.%Y %H:%M}";
	  tooltip-format = "{:%A, %d %B %Y %H:%M:%S}";
	};
        battery = {
          interval = 5;
	  format = "Pow: {}%";
	  format-charging = "Pow: {}% charging";
	};
	"ext/workspaces" = {
    	  format = "{icon}";
    	  ignore-hidden = true;
    	  on-click = "activate";
    	  on-click-right = "deactivate";
    	  sort-by-id = true;
  	};
	"custom/network" = {
          interval = 5;
          format = "{}";
          return-type = "json";

          exec = let
            networkStatus = pkgs.writeShellApplication {
              name = "network-status";
              runtimeInputs = [
                pkgs.iw
                pkgs.wirelesstools
                pkgs.gnugrep
                pkgs.iproute2
                pkgs.coreutils
              ];
              checkPhase = "";
              text = ''
                # Get SSID (if Wi-Fi)
                ssid=$(iwgetid -r)
                # Check Internet connectivity
                if ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; then
                  if [ -z "$ssid" ]; then
                    ssid="Ethernet"
                  fi
                  text="Net: $ssid"
                  tooltip="Connected network: $ssid"
                else
                  text="No connection"
                  tooltip="No internet connection"
                fi

                echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\"}"
              '';
            };
          in "${networkStatus}/bin/network-status";

          # Open nmtui when clicked (change 'foot' to your preferred terminal)
          on-click = "alacritty -e nmtui";
        };
	"custom/bluetooth" = {
          interval = 8;
          format = "{}";
          return-type = "json";

          exec = let
            btStatus = pkgs.writeShellApplication {
              name = "bt-status";
              runtimeInputs = [ pkgs.bluez pkgs.gnugrep pkgs.gawk pkgs.coreutils ];
              checkPhase = "";
              text = ''
                # Pick working command
                if bluetoothctl --help | grep -q "connected-devices"; then
                  devices_raw=$(bluetoothctl connected-devices)
                else
                  devices_raw=$(bluetoothctl devices Connected)
                fi

                # If no devices connected
                if [ -z "$devices_raw" ]; then
                  echo '{"text": "BT none", "tooltip": "No Bluetooth devices connected"}'
                  exit 0
                fi

                display_text=""
                tooltip="Connected Bluetooth devices:\n"

                # Use a temporary file to loop without losing scope
                tmpfile=$(mktemp)
                echo "$devices_raw" > "$tmpfile"

                while read -r _ mac rest; do
                  [ -z "$mac" ] && continue
                  name=$(echo "$rest" | sed 's/^[[:space:]]*//')

                  # Try to read the battery percentage
                  battery=$(bluetoothctl info "$mac" 2>/dev/null | grep "Battery Percentage" | grep -o "[0-9]\\+%" || true)

                  if [ -n "$battery" ]; then
                    entry="$name ($battery)"
                  else
                    entry="$name"
                  fi

                  tooltip="$tooltip$entry\n"

                  if [ -z "$display_text" ]; then
                    display_text="$entry"
                  else
                    display_text="$display_text, $entry"
                  fi
                done < "$tmpfile"

                rm -f "$tmpfile"

                # Fallback if parsing failed
                [ -z "$display_text" ] && display_text="unknown"

                echo "{\"text\": \"BT $display_text\", \"tooltip\": \"$tooltip\"}"
              '';
            };
          in "${btStatus}/bin/bt-status";

          on-click = "blueman-manager";
        };
        "custom/pamixer" = {
          interval = 1;
          format = "{}";
          return-type = "json";

          exec = let
            pamixerStatus = pkgs.writeShellApplication {
              name = "pamixer-status";
              runtimeInputs = [ pkgs.pamixer ];
              checkPhase = "";  # disable ShellCheck
              text = ''
                volume=$(pamixer --get-volume)
                muted=$(pamixer --get-mute)

                if [ "$muted" = "true" ]; then
                  text="Muted"
                else
                  text="Vol: $volume%"
                fi

                echo "{\"text\": \"$text\", \"tooltip\": \"$text\"}"
              '';
            };
          in "${pamixerStatus}/bin/pamixer-status";

          on-click = "pamixer -t";
          on-scroll-up = "pamixer -i 5";
          on-scroll-down = "pamixer -d 5";
        };
      };
    };
  };
}
