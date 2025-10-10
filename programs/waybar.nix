{ config, pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    style = ''
      window#waybar {
        background-color: #ff5fd7;
	font-family: "JetBrains Nerd Font", monospace;
	font-size: 12px;
      }
    '';
    settings = {
      main = {
        modules-right = [ "custom/pamixer" "battery" "clock" ];

	"custom/pamixer" = {
                  interval = 2;
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
