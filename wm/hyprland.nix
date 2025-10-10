{ config, pkgs, ... }:
{
    wayland = {
    systemd.target = "wayland-session.target";
    windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = null;
      extraConfig = ''
        input {
          kb_layout = pl
	}
      '';
      settings = {
        general = {
          border_size = 1;
	  gaps_in = 2;
	  gaps_out = 4;
	  "col.active_border" = "rgba(ff5fd7ff) rgba(ff5fd7ff) 0deg";
	  "col.inactive_border" = "rgba(5f5fffff) rgba(5f5fffff) 0deg";
	};
	decoration = {
          rounding = 2;
	  rounding_power = "2.0";
	  inactive_opacity = "0.7";
	  blur = {
            enabled = true;
	    size = 4;
	  };
	};
        misc = {
          disable_hyprland_logo = true;
	};
        "$mod" = "SUPER";
        bind = [
	  "$mod, D, exec, fuzzel"
	  "$mod, L, exec, bash kbm"
          "$mod, B, exec, firefox"
	  "$mod, Q, exec, alacritty"

	  "$mod, 1, workspace, 1"
	  "$mod, 2, workspace, 2"
	  "$mod, 3, workspace, 3"
	  "$mod, 4, workspace, 4"
	  "$mod, 5, workspace, 5"
	  "$mod, 6, workspace, 6"
	  "$mod, 7, workspace, 7"
	  "$mod, 8, workspace, 8"
	  "$mod, 9, workspace, 9"

	  "$mod SHIFT, 1, movetoworkspace, 1"
	  "$mod SHIFT, 2, movetoworkspace, 2"
	  "$mod SHIFT, 3, movetoworkspace, 3"
	  "$mod SHIFT, 4, movetoworkspace, 4"
	  "$mod SHIFT, 5, movetoworkspace, 5"
	  "$mod SHIFT, 6, movetoworkspace, 6"
	  "$mod SHIFT, 7, movetoworkspace, 7"
	  "$mod SHIFT, 8, movetoworkspace, 8"
	  "$mod SHIFT, 9, movetoworkspace, 9"

	  "F1, exec, bash pamixer -t"
          "F2, exec, bash pamixer --allow-boost -d 5"
          "F3, exec, bash pamixer --allow-boost -i 5"
	];
        bindm = [
          "$mod, mouse:272, movewindow"
	  "$mod, mouse:273, resizewindow"
	  "$mod ALT, mouse:272, resizewindow"
        ];
	exec-once = [
          "sleep 1 && hyprpaper"
	  "waybar"
	];
      };
    };
  };
}
