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
        bind=super,b,spawn,firefox
        bind=super,q,spawn,alacritty
      '';
      description = "Main Mango configuration file.";
    };

    autostartScript = lib.mkOption {
      type = lib.types.lines;
      default = ''
        #!/usr/bin/env bash
        sleep 1
        hyprpaper &
        waybar &
      '';
      description = "Autostart script for Mango window manager.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install MangoWC
    home.packages = [ cfg.package ];

    # Mango config file
    xdg.configFile."mango/config.toml".text = cfg.configFile;

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
      Exec=mangowc --config ~/.config/mango/config.toml
      Type=Application
      DesktopNames=MangoWC
    '';
  };
}
