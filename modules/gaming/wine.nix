{ pkgs, ... }:

# ── Wine ───────────────────────────────────────────────────────────────────────
# wineWowPackages.stable ships both 32-bit and 64-bit Wine in one package,
# which is what most Windows games and apps expect.
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    winetricks
  ];
}
