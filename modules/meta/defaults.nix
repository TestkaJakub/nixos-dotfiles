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
# Wallpaper: kept as a plain string path. Copying /home paths into the Nix
# store at eval time is forbidden in pure evaluation mode. If SDDM ever fails
# to read the wallpaper, the practical fix is to commit the image into the
# dotfiles repo and reference it as ./path/to/image, or fetch it with pkgs.fetchurl.
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
      default     = "${config.profile.homeDirectory}/Wallpapers/AkuNoHana.jpg";
      description = ''
        Absolute path to the wallpaper image. Used by hyprpaper (user session)
        and SDDM (system service). In practice SDDM can read /home paths fine
        on a single-disk setup where home is available at display manager start.
        To make this fully store-backed, commit the image into the repo and
        reference it as a relative path or via pkgs.fetchurl with a known hash.
      '';
    };
  };
}
