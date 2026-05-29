{ pkgs, ... }:

# ── Vivaldi ────────────────────────────────────────────────────────────────────
{
  environment.systemPackages = [
    (pkgs.vivaldi.override {
      commandLineArgs = [
        "--ozone-platform=x11"
        "--gtk-version=3"
      ];
    })
  ];
}