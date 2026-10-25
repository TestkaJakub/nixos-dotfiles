{ config, ... }:

# ── Dunst — notifications ──────────────────────────────────────────────────────
# Managed as a home-manager service so Stylix themes it (colors + font).
# D-Bus activated: it starts on the first notification in both i3 and sway,
# so the WM configs no longer exec it.
#
# Only layout lives here — colors and font come from Stylix (meta/7.stylix.nix).
#
# Test:  notify-send "Hello" "This is dunst"
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.services.dunst = {
    enable = true;
    settings.global = {
      origin             = "top-right";
      width              = 360;
      corner_radius      = 5;
      frame_width        = 3;
      gap_size           = 8;
      padding            = 12;
      horizontal_padding = 14;
      icon_position      = "left";
      max_icon_size      = 48;
    };
  };
}