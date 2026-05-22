{ pkgs, ... }:

# ── Vivaldi ────────────────────────────────────────────────────────────────────
{
  environment.systemPackages = [ pkgs.vivaldi ];
}
