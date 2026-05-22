{ config, ... }:

# ── Wallpaper ──────────────────────────────────────────────────────────────────
# Reads: config.meta.defaults.wallpaper
#        config.profile.username
#
# hyprpaper is launched by desktop/compositor.nix autostart.
# This module provides its config file so it knows which image to load.
let
  user      = config.profile.username;
  wallpaper = config.meta.defaults.wallpaper;
in
{
  home-manager.users.${user} = {
    # hyprpaper config — preloads the image and sets it on all monitors
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${wallpaper}
      wallpaper = ,${wallpaper}
      splash = false
    '';

    # swww daemon for animated wallpaper switching (available as fallback)
    services.swww.enable = true;
  };
}
