{ pkgs, ... }:

# ── Discord ────────────────────────────────────────────────────────────────────
{
  environment.systemPackages = [ pkgs.discord ];
}
