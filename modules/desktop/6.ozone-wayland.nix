{ ... }:

# ── Electron/Chromium Wayland (Ozone) ──────────────────────────────────────────
# Pushes Electron and Chromium apps (Discord, VSCodium, browsers) onto native
# Wayland instead of XWayland. Under Sway this fixes fractional-scale blur and
# lets these apps be seen/shared through the Wayland screencast portal.
#
# Only takes effect in a Wayland session. Under i3 (X11) it's a harmless no-op —
# there's no Wayland display, so Ozone falls back to X11 automatically.
{
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}