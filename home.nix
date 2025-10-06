{ config, pkgs, ... }:
{
#  home-manager.backupFileExtension = "backup";
  home = {
    username = "jakub";
    stateVersion = "25.05";
    packages = with pkgs; [
      bat
      btop
      git
      arduino-core
      arduino-cli
      fastfetch
      hyprpaper
    ];
  };
  #services.hyprpaper.enable = true;

  imports = [
    ./bash.nix
  ];

  programs.waybar = {
    enable = true;
    settings = {
      main = {
        modules-right = ["clock"];
      };
    };
  };

  programs.home-manager = { 
    enable = true;
  };

  programs.fastfetch = {
    enable = true;
  };

  programs.alacritty = {
      enable = true;
      settings = {
      	window = {
	  opacity = 0.9;
          padding = {
            x = 10;
	    y = 10;
	  };
	};
        font.normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
      };
    };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      #gruvbox-material # theme
      solarized # theme ? 
      syntastic # syntax highlighting for many languages
      emmet-vim # :tag tag creation
      tabular # :tab tag for aligning stuff
      
    ];
  };

  wayland = {
    systemd.target = "wayland-session.target";
    windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = null;
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
	  "$mod, L, exec, bash kbm"
          "$mod, B, exec, firefox"
	  "$mod, Q, exec, alacritty"
        ];
        bindm = [
          "$mod, mouse:272, movewindow"
	  "$mod, mouse:273, resizewindow"
	  "$mod ALT, mouse:272, resizewindow"
        ];
	exec-once = [
          "sleep 1 && hyprpaper && waybar"
	];
      };
    };
  };

 xdg.configFile."hypr/hyprpaper.conf".text = ''
   preload = ~/Wallpapers/toradora.png
   wallpaper = , ~/Wallpapers/toradora.png
 '';

 home.file.".config/bat/config".text = ''
    --theme="Nord"
    --style="numbers,changes,grid"
    --paging=auto
  '';

  home.file.".config/qtile".source = ./qtile;
}

