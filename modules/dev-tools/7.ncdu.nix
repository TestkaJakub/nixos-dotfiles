{ pkgs, ... }:

# ── ncdu ───────────────────────────────────────────────────────────────────────
# Interactive disk usage explorer.
# Waybar button (custom/ncdu) in desktop/bar.nix opens it on ~ in a terminal.
{
  environment.systemPackages = [ pkgs.ncdu ];
}
