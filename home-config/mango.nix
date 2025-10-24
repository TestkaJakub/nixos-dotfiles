{ lib, config, pkgs, ... }:

{
  options.wayland.windowManager.mango.enable =
    lib.mkEnableOption "Enable Mango window manager for Wayland";

  options.wayland.windowManager.mango.settings = lib.mkOption {
    type = lib.types.lines;
    default = ''
      bind=SUPER, b, spawn firefox
      bind=SUPER, t, spawn alacritty
    '';
    description = "Configuration for Mango window manager";
  };

  options.wayland.windowManager.mango.autostart_sh = lib.mkOption {
    type = lib.types.lines;
    default = ''
      sleep 1 && hyprpaper
      waybar
    '';
    description = "Autostart script for Mango window manager";
  };

  config = lib.mkIf config.wayland.windowManager.mango.enable {
    home.packages = [ pkgs.mangowc ];
    xdg.configFile."mango/config".text = config.wayland.windowManager.mango.settings;
    xdg.configFile."mango/autostart.sh".text = config.wayland.windowManager.mango.autostart_sh;
  };
}