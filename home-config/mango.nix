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
	bind=super,d,spawn,fuzzel
	bind=super,w,killclient
	bind=super,Tab,focusstack,next
	bind=super,Left,focusdir,left
	bind=super,Right,focusdir,right
	bind=super,Up,focusdir,up
	bind=super,Down,docusdir,dowm
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
