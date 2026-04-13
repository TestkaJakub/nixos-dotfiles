{ pkgs, ... }:

# ── Graphics ───────────────────────────────────────────────────────────────────
# Single authoritative graphics config for AMD hardware.
# gaming/steam.nix adds its own extraPackages on top via mkMerge semantics.
{
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      #amdvlk
      libdrm  # low-level DRM access
    ];
  };
}
