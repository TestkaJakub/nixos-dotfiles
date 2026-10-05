{ lib, config, pkgs, ... }:
{
  options.meta.defaults = {
    browser = lib.mkOption {
      type        = lib.types.str;
      default     = "librewolf";
      description = "Binary name of the default web browser.";
    };

    browserDesktop = lib.mkOption {
      type        = lib.types.str;
      default     = "librewolf.desktop";
      description = "Desktop entry name for the default web browser (used by xdg-open).";
    };

    browserPackage = lib.mkOption {
      type        = lib.types.package;
      default     = pkgs.librewolf;
      description = "Package for the default web browser.";
    };

    terminal = lib.mkOption {
      type        = lib.types.str;
      default     = "wezterm";
      description = "Binary name of the default terminal emulator.";
    };

    terminalPackage = lib.mkOption {
      type        = lib.types.package;
      default     = pkgs.wezterm;
      description = "Package for the default terminal emulator.";
    };

    terminalRun = lib.mkOption {
      type        = lib.types.str;
      default     = "${pkgs.wezterm}/bin/wezterm start --";
      description = "Prefix used to run a command inside the default terminal.";
    };

    fileManager = lib.mkOption {
      type        = lib.types.str;
      default     = "nemo";
      description = "Binary name of the default file manager.";
    };

    fileManagerDesktop = lib.mkOption {
      type        = lib.types.str;
      default     = "nemo.desktop";
      description = "Desktop entry name for the default file manager.";
    };

    fileManagerPackage = lib.mkOption {
      type        = lib.types.package;
      default     = pkgs.nemo;
      description = "Package for the default file manager.";
    };

    editor = lib.mkOption {
      type        = lib.types.str;
      default     = "${pkgs.micro}/bin/micro";
      description = "Full path to the default editor binary.";
    };

    wallpaper = lib.mkOption {
      type        = lib.types.str;
      default     = toString ./wallpapers/AkuNoHana.jpg;
      description = ''
        Absolute store path to the wallpaper image. Stored in the repo under
        modules/meta/wallpapers/ so it is store-backed and reproducible.
        To change wallpapers: commit the new image to that directory and
        update the default here.
      '';
    };
  };

  config.home-manager.users.${config.profile.username}.xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"                = config.meta.defaults.browserDesktop;
      "x-scheme-handler/http"   = config.meta.defaults.browserDesktop;
      "x-scheme-handler/https"  = config.meta.defaults.browserDesktop;
      "x-scheme-handler/about"  = config.meta.defaults.browserDesktop;
      "x-scheme-handler/unknown" = config.meta.defaults.browserDesktop;
    };
  };
}