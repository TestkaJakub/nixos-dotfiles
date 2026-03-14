{ lib, config, pkgs, ... }:

# ── Meta / default applications ────────────────────────────────────────────────
# Single place to change which app opens for each role.
# Values flow into:
#   - xdg.mimeApps           (what opens when you click a file/link)
#   - desktop/compositor.nix (keybinds: super+b, super+q, super+e)
#   - desktop/wallpaper.nix  (hyprpaper config)
#   - desktop/display.nix    (SDDM theme background)
#   - desktop/bar.nix        (network widget click)
#
# Wallpaper note: the path must be readable by SDDM, which runs as a system
# service before any user session exists. To guarantee this, the image is
# copied into the Nix store at eval time via builtins.path. The resulting
# store path is world-readable and survives across rebuilds identically.
# To change wallpaper: replace wallpaperSource below and rebuild.
let
  wallpaperSource = /home/jakub/Wallpapers/AkuNoHana.jpg;

  wallpaperStore = builtins.path {
    path = wallpaperSource;
    name = "wallpaper";
  };
in
{
  options.meta.defaults = {
    browser = lib.mkOption {
      type        = lib.types.str;
      default     = "vivaldi";
      description = "Binary name of the default web browser.";
    };

    browserDesktop = lib.mkOption {
      type        = lib.types.str;
      default     = "vivaldi.desktop";
      description = "Desktop entry name for the default web browser (used by xdg-open).";
    };

    browserPackage = lib.mkOption {
      type        = lib.types.package;
      default     = pkgs.vivaldi;
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

    # Full prefix for spawning a command inside the terminal, e.g.:
    #   "${meta.defaults.terminalRun} nmtui"
    # Kept as a string because the sub-command syntax differs per terminal.
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

    wallpaper = lib.mkOption {
      type        = lib.types.str;
      default     = wallpaperStore;
      description = ''
        Nix store path to the wallpaper image. Defaults to a store-copied
        version of ~/Wallpapers/AkuNoHana.jpg so it is readable by SDDM
        (a system service) and by hyprpaper alike. Change wallpaperSource
        at the top of this file to switch images.
      '';
    };
  };
}
