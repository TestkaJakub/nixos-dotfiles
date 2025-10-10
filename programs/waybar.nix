{ config, pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    style = ''
      window#waybar {
        background-color: #ff5fd7;
      }
    '';
    settings = {
      main = {
        modules-right = [ "custom/pamixer" "battery" "clock" ];

	"custom/pamixer" = {
	  interval = 2;
	  format = "audio {}%";
	  return-type = "json";
	  exec = "${pkgs.writeShellScript "pamixer-status.sh" ''
	    volue=$(pamixer --get-volume)
	    muted=$(pamixer --get-mute)

	    if [ "$muted" = "true" ]; then
              icon=""
            elif [ "$volume" -lt 30 ]; then
              icon=""
            elif [ "$volume" -lt 70 ]; then
              icon=""
	    else
              icon=""
            fi

            echo "{\"text\": \"$icon $volume%\", \"tooltip\": \"Volume: $volume%\"}"
	  ''
	  };
	};
      };
    };
  };
}
