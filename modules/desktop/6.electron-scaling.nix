{ config, ... }:

# ── Electron HiDPI scaling ─────────────────────────────────────────────────────
# Electron apps ignore Xft.dpi on X11, so each needs an explicit scale factor.
# Keep in sync with Xft.dpi in desktop/filemanager.nix (131 / 96 = 1.36667).
let
  user  = config.profile.username;
  flags = "--force-device-scale-factor=1.36667\n";
in
{
  home-manager.users.${user}.home.file = {
    ".config/electron-flags.conf".text = flags;
    ".config/discord-flags.conf".text  = flags;
    ".config/obsidian-flags.conf".text = flags;
    ".config/codium-flags.conf".text   = flags;
  };
}