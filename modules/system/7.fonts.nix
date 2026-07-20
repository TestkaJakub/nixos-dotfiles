{ pkgs, ... }:

# ── Fonts ──────────────────────────────────────────────────────────────────────
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      antialias = true;
      hinting   = { enable = true; style = "slight"; };
      subpixel  = { rgba = "none"; };
    };
  };
}
