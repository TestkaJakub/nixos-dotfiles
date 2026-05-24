{ pkgs, ... }:

# ── Prism Launcher ─────────────────────────────────────────────────────────────
# Multi-instance Minecraft launcher with mod support.
{
  environment.systemPackages = [ pkgs.prismlauncher ];
}
