{ pkgs, ... }:

# ── GoldenDict-ng ──────────────────────────────────────────────────────────────
# Offline dictionary with CEDICT support for Chinese lookups.
# To add CEDICT: open GoldenDict → Edit → Dictionaries → add the .txt file.
{
  environment.systemPackages = [ pkgs.goldendict-ng ];
}
