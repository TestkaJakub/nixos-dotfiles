{ config, pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    style = ''
      window#waybar {
        background-color: #ff5fd7;
	font-family: "JetBrains Nerd Font", monospace;
	font-size: 12px;
	border: 1px solid #555555;
      }
      .module {
        border: 1px solid #555555;
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
        background: #ff78dd;
        color: #000000;
      }

      #workspaces button.urgent {
        background: #ff92e4;
        color: #ffffff;
      }
    '';
    settings = {
      main = {
        modules-left = [ "ext/workspaces" ];
        modules-right = [ "custom/bluetooth" "custom/network" "custom/pamixer" "battery" "clock" ];

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
            runtimeInputs = [ pkgs.iw pkgs.wirelesstools pkgs.gnugrep ];
            checkPhase = "";
            text = ''
              ssid=$(iwgetid -r)
              if [ -z "$ssid" ]; then
                ssid="No WiFi"
              fi

              echo "{\"text\": \"Net: $ssid\", \"tooltip\": \"Connected network: $ssid\"}"
            '';
          };
          in "${networkStatus}/bin/network-status";
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
        	  # Use compatible detection command
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

        	  echo "$devices_raw" | while read -r _ mac name_rest; do
          	  [ -z "$mac" ] && continue

                  name=$(echo "$name_rest" | sed 's/^[[:space:]]*//')
                  battery=$(bluetoothctl info "$mac" | grep "Battery Percentage" | grep -o "[0-9]\\+%" || true)

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
                done

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
