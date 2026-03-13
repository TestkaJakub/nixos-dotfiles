{ pkgs, config, ... }:

# ── Obsidian ───────────────────────────────────────────────────────────────────
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.home.packages = [ pkgs.obsidian ];
}
