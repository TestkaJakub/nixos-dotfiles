{ pkgs, config, ... }:

# ── Productivity ───────────────────────────────────────────────────────────────
#   obsidian      — knowledge base / markdown notes
#   libreoffice   — office suite
let
  user = config.profile.username;
in
{
  environment.systemPackages = [ pkgs.libreoffice-qt-fresh ];

  home-manager.users.${user}.home.packages = [ pkgs.obsidian ];
}
