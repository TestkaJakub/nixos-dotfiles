{ config, ... }:

# ── Wallpaper ──────────────────────────────────────────────────────────────────
# swww daemon managed by home-manager.
# hyprpaper is installed as a package; it is launched by the compositor
# autostart script in desktop/compositor.nix.
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.services.swww.enable = true;
}
