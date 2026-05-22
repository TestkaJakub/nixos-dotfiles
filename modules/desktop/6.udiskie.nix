{ config, ... }:

# ── udiskie ────────────────────────────────────────────────────────────────────
# Removable media automounter with a systray icon.
# The tray icon appears in Waybar's tray module (desktop/bar.nix).
#
# services.udisks2 is already enabled in system/peripherals.nix — udiskie
# sits on top of it and adds automounting + the tray icon.
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.services.udiskie = {
    enable    = true;
    tray      = "always";
    automount = true;
    notify    = true;
  };
}
