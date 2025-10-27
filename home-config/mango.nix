{ lib, config, pkgs, inputs, ... }:

let
  # Simplify references
  cfg = config.wayland.windowManager.mango;

in
{
  options.wayland.windowManager.mango = {
    enable = lib.mkEnableOption "Enable Mango window manager for Wayland";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.mangowc.packages.${pkgs.system}.default;
      description = "The MangoWC compositor package to use.";
    };

    configFile = lib.mkOption {
      type = lib.types.lines;
      default = ''
        bind=super,r,reload_config
        bind=super,q,spawn,alacritty
        bind=super,b,spawn,firefox
	bind=super,f,spawn,fuzzel
	bind=super,e,killclient

	bind=super,Tab,focusstack,next

	bind=super,a,focusdir,left
	bind=super,d,focusdir,right
	bind=super,w,focusdir,up
	bind=super,s,focusdir,down

        bind=super,x,togglefullscreen
	bind=super,v,togglemaxmizescreen
	bind=super,c,togglefloating

	bind=super,1,comboview,1
	bind=super,2,comboview,2
	bind=super,3,comboview,3
	bind=super,4,comboview,4
	bind=super,5,comboview,5
	bind=super,6,comboview,6
	bind=super,7,comboview,7
	bind=super,8,comboview,8
	bind=super,9,comboview,9

	bind=super,t,setlayout,tile
	bind=super,y,setlayout,vertical_grid
	bind=super,u,setlayout,spiral
	bind=super,i,setlayout,scroller
	bind=super,o,switch_layout
	bind=super,p,togglegaps

	bind=super,k,exchange_client,up
	bind=super,j,exchange_client,down
	bind=super,h,exchange_client,left
	bind=super,l,exchange_client,right

	bind=super,g,spawn,bash kbm
	bind=super,m,spawn,bash,cpc

        bind=none,XF86AudioMute,spawn,pamixer -t
        bind=none,XF86AudioLowerVolume,spawn,pamixer --allow-boost -d 5
        bind=none,XF86AudioRaiseVolume,spawn,pamixer --allow-boost -i 5

        focuscolor=0xff5fd7ff
	bordercolor=0x5f5fffff
      '';
      description = "Main Mango configuration file.";
    };

    autostartScript = lib.mkOption {
      type = lib.types.lines;
      default = ''
        #!/usr/bin/env bash
        sleep 1
        hyprpaper --config ~/nixos-dotfiles/home-config/hyprpaper.conf &
        waybar &
      '';
      description = "Autostart script for Mango window manager.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install MangoWC
    home.packages = [ cfg.package ];

    # Mango config file
    xdg.configFile."mango/config.conf".text = cfg.configFile;

    # Executable autostart script
    xdg.configFile."mango/autostart.sh" = {
      text = cfg.autostartScript;
      executable = true;
    };

    # Desktop session entry so SDDM can launch Mango
    xdg.dataFile."wayland-sessions/mangowc.desktop".text = ''
      [Desktop Entry]
      Name=MangoWC
      Comment=Mango window manager
      Exec=mangowc --config ~/.config/mango/config.conf
      Type=Application
      DesktopNames=MangoWC
    '';
  };
}
