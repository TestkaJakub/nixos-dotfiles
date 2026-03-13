{ lib, config, ... }:

# ── Meta / default applications ────────────────────────────────────────────────
# Single place to change which app opens for each role.
# Values flow into:
#   - xdg.mimeApps           (what opens when you click a file/link)
#   - desktop/compositor.nix (keybinds: super+b, super+q, super+e)
#   - desktop/wallpaper.nix  (hyprpaper config)
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

    terminal = lib.mkOption {
      type        = lib.types.str;
      default     = "alacritty";
      description = "Binary name of the default terminal emulator.";
    };

    fileManager = lib.mkOption {
      type        = lib.types.str;
      default     = "yazi";
      description = "Binary name of the default file manager.";
    };

    fileManagerDesktop = lib.mkOption {
      type        = lib.types.str;
      default     = "yazi.desktop";
      description = "Desktop entry name for the default file manager.";
    };

    wallpaper = lib.mkOption {
      type        = lib.types.str;
      default     = "${config.profile.homeDirectory}/Wallpapers/AkuNoHana.jpg";
      description = "Absolute path to the wallpaper image.";
    };
  };
}
