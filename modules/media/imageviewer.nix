{ pkgs, config, ... }:

# ── swayimg — image viewer ─────────────────────────────────────────────────────
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.home.packages = [ pkgs.swayimg ];
}
