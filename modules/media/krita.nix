{ pkgs, ... }:

# ── Krita ──────────────────────────────────────────────────────────────────────
# Digital painting and illustration.
# Tablet support (OpenTabletDriver, xf86_input_wacom) is provided by
# system/peripherals.nix — no duplication needed here.
{
  environment.systemPackages = with pkgs; [
    krita
    xf86_input_wacom   # Xorg wacom driver (used even under XWayland)
    libinput           # input event library
  ];
}
