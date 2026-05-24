{ pkgs, ... }:

# ── btop ───────────────────────────────────────────────────────────────────────
# Interactive resource monitor.
# Waybar button (custom/btop) in desktop/bar.nix opens it in a terminal.
{
  environment.systemPackages = [ pkgs.btop ];
}
