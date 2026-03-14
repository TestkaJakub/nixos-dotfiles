{ pkgs, config, ... }:

# ── Waybar ─────────────────────────────────────────────────────────────────────
let
  t    = config.theme;
  user = config.profile.username;
  meta = config.meta.defaults;

  lightenedPrimary  = t.functions.lighten t.palette.primary 0.1;
  waybarFocusedText = t.functions.textcolor lightenedPrimary;
  waybarText        = t.functions.textcolor t.palette.primary;
  urgentBg          = t.functions.complement t.palette.primary;
  urgentFg          = t.functions.textcolor urgentBg;

  # Full store paths so scripts work regardless of PATH
  jq           = "${pkgs.jq}/bin/jq";
  ping         = "${pkgs.iputils}/bin/ping";
  iwgetid      = "${pkgs.wirelesstools}/bin/iwgetid";
  pamixer      = "${pkgs.pamixer}/bin/pamixer";
  bluetoothctl = "${pkgs.bluez}/bin/bluetoothctl";
  blueman      = "${pkgs.blueman}/bin/blueman-manager";
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
        background: ${urgentBg};
        color: ${urgentFg};
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
        # terminalRun carries the full store path + correct sub-command syntax
        # for whatever terminal is set as default, e.g. "wezterm start -- nmtui"
        on-click    = "${meta.terminalRun} nmtui";
        exec = pkgs.writeShellScript "waybar-network" ''
          ssid=$(${iwgetid} -r 2>/dev/null || echo "")
          if ${ping} -c1 -W1 8.8.8.8 >/dev/null 2>&1; then
            [ -z "$ssid" ] && ssid="Ethernet"
            ${jq} -Rcn --arg text "Net: $ssid" --arg tooltip "Connected: $ssid" \
              '{text: $text, tooltip: $tooltip}'
          else
            ${jq} -Rcn '{text: "No connection", tooltip: "No internet connection"}'
          fi
        '';
      };

      "custom/bluetooth" = {
        interval    = 8;
        format      = "{}";
        return-type = "json";
        on-click    = "${blueman}";
        exec = pkgs.writeShellScript "waybar-bluetooth" ''
          if ${bluetoothctl} --help | grep -q "connected-devices"; then
            devices_raw=$(${bluetoothctl} connected-devices 2>/dev/null)
          else
            devices_raw=$(${bluetoothctl} devices Connected 2>/dev/null)
          fi

          if [ -z "$devices_raw" ]; then
            ${jq} -Rcn '{text: "BT none", tooltip: "No Bluetooth devices connected"}'
            exit 0
          fi

          display_text=""
          tooltip="Connected Bluetooth devices:\n"

          while read -r _ mac rest; do
            [ -z "$mac" ] && continue
            name=$(echo "$rest" | sed 's/^[[:space:]]*//')
            battery=$(${bluetoothctl} info "$mac" 2>/dev/null \
              | grep "Battery Percentage" | grep -o "[0-9]\+%" || true)
            [ -n "$battery" ] && entry="$name ($battery)" || entry="$name"
            tooltip="$tooltip$entry\n"
            [ -n "$display_text" ] && display_text="$display_text, $entry" || display_text="$entry"
          done <<< "$devices_raw"

          [ -z "$display_text" ] && display_text="unknown"
          ${jq} -Rcn \
            --arg text "BT $display_text" \
            --arg tooltip "$tooltip" \
            '{text: $text, tooltip: $tooltip}'
        '';
      };

      "custom/pamixer" = {
        interval       = 1;
        format         = "{}";
        return-type    = "json";
        on-click       = "${pamixer} -t";
        on-scroll-up   = "${pamixer} -i 5";
        on-scroll-down = "${pamixer} -d 5";
        exec = pkgs.writeShellScript "waybar-volume" ''
          volume=$(${pamixer} --get-volume 2>/dev/null || echo 0)
          muted=$(${pamixer} --get-mute 2>/dev/null || echo false)
          if [ "$muted" = "true" ]; then
            ${jq} -Rcn '{text: "Muted", tooltip: "Muted"}'
          else
            ${jq} -Rcn --arg v "$volume" '{text: "Vol: \($v)%", tooltip: "Vol: \($v)%"}'
          fi
        '';
      };
    };
  };
}
