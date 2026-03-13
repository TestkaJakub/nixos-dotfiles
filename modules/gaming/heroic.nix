{ pkgs, ... }:

# ── Heroic Games Launcher ──────────────────────────────────────────────────────
# GOG, Epic Games Store, and Amazon Games client for Linux.
{
  environment.systemPackages = [ pkgs.heroic ];
}
