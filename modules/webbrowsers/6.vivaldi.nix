{ pkgs, ... }:

# ── Vivaldi ────────────────────────────────────────────────────────────────────
# commandLineArgs are passed on every launch. --ozone-platform=auto lets
# Chromium pick Wayland or X11 based on the running session automatically.
{
  environment.systemPackages = [
    (pkgs.vivaldi.override {
      commandLineArgs = [
        "--ozone-platform-hint=auto"
        "--enable-features=WaylandWindowDecorations,UseOzonePlatform"
        "--gtk-version=4"
      ];
    })
  ];
}