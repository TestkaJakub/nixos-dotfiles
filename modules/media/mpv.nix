{ pkgs, config, ... }:

# ── mpv ────────────────────────────────────────────────────────────────────────
# General-purpose media player. Handles video, audio, and camera feeds.
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.home.packages = [ pkgs.mpv ];
}
