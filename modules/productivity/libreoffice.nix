{ pkgs, ... }:

# ── LibreOffice ────────────────────────────────────────────────────────────────
{
  environment.systemPackages = [ pkgs.libreoffice-qt-fresh ];
}
