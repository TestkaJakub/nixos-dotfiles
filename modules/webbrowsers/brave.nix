{ pkgs, ... }:

# ── Brave ──────────────────────────────────────────────────────────────────────
# System package — available to all users and on the login screen.
{
  environment.systemPackages = [ pkgs.brave ];
}
