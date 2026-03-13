{ pkgs, ... }:

# ── Thunar ─────────────────────────────────────────────────────────────────────
# Thunar needs gvfs (already enabled in system/peripherals.nix) for MTP,
# network shares, and trash. tumbler provides thumbnail generation.
{
  environment.systemPackages = with pkgs; [
    xfce.thunar
    xfce.thunar-volman
    xfce.tumbler
  ];

  programs.thunar.enable = true;
}
