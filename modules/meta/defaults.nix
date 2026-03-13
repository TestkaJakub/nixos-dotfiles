{ lib, config, pkgs, ... }:

# ── Meta / default applications ────────────────────────────────────────────────
# Single place to change which app opens for each role.
# Values flow into:
#   - xdg.mimeApps          (what opens when you click a file/link)
#   - desktop/compositor.nix (keybinds: super+b, super+q, super+e)
#   - desktop/wallpaper.nix  (hyprpaper config + swww)
#
# To switch default browser to firefox: set options.meta.defaults.browser = "firefox"
# The keybind, xdg-open, and MIME associations all update on next rebuild.

{
  options.meta.defaults = {
	  browser = lib.mkOption {
	    type        = lib.types.str;
	    default     = "vivaldi";
	    description = "Binary name of the default web browser.";
	  };

	  browserDesktop = lib.mkOption {
	    type        = lib.types.str;
	    default     = "vivaldi-stable.desktop";
	    description = "Desktop entry name for the default web browser (used by xdg-open).";
	  };

	  terminal = lib.mkOption {
	    type        = lib.types.str;
	    default     = "alacritty";
	    description = "Binary name of the default terminal emulator.";
	  };

	  fileManager = lib.mkOption {
	    type        = lib.types.str;
	    default     = "thunar";
	    description = "Binary name of the default file manager.";
	  };

	  fileManagerDesktop = lib.mkOption {
	    type        = lib.types.str;
	    default     = "thunar.desktop";
	    description = "Desktop entry name for the default file manager.";
	  };

	  wallpaper = lib.mkOption {
	    type        = lib.types.str;
	    default     = "~/Wallpapers/AkuNoHana.jpg";
	    description = "Absolute or home-relative path to the wallpaper image.";
	  };
  };
}
