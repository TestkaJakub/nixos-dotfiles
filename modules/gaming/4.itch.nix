{ pkgs, ... }:

# ── itch ───────────────────────────────────────────────────────────────────────
# Desktop client for itch.io — download, install, and auto-update indie games.
{
  environment.systemPackages = [ pkgs.itch ];
}
