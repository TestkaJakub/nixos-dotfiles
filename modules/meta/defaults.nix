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
# Wallpaper note: wallpaper is declared as a derivation (via pkgs.copyPathToStore)
# rather than a raw /home path. This makes it readable by SDDM, which runs as a
# system service before /home is necessarily available. To change the wallpaper,
# replace the path passed to pkgs.copyPathToStore below and rebuild.
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
      type        = lib.types.path;
      default     = pkgs.copyPathToStore /home/jakub/Wallpapers/AkuNoHana.jpg;
      description = ''
        Path to the wallpaper image. The default uses pkgs.copyPathToStore so
        the file lands in the Nix store and is world-readable by system services
        like SDDM. To change wallpaper, pass a different path to copyPathToStore,
        or assign any other store path / derivation output.
      '';
    };
  };
}
