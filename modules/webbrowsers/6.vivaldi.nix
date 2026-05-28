{ pkgs, ... }:

# ── Vivaldi ────────────────────────────────────────────────────────────────────
# --gtk-version=4 is kept: KDE Plasma has GTK4 loaded in the session, and
# Vivaldi needs to match or it crashes with GTK type registration conflicts.
{
  environment.systemPackages = [
    (pkgs.vivaldi.override {
      commandLineArgs = [
        "--gtk-version=4"
      ];
    })
  ];
}