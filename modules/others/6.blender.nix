{ pkgs, ... }:

# ── Blender ────────────────────────────────────────────────────────────────────
# 3D modelling, animation, and rendering suite.
{
  environment.systemPackages = [ pkgs.blender ];
}
