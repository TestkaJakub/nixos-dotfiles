{ pkgs, config, ... }:

# ── Productivity ───────────────────────────────────────────────────────────────
#   obsidian
#   libreoffice
let
  user = config.profile.username;
in
{
  environment.systemPackages = [ pkgs.libreoffice-qt-fresh ];

  home-manager.users.${user}.home.packages = [ pkgs.obsidian ];
}
