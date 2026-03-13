{ pkgs, ... }:

# ── Peripherals ────────────────────────────────────────────────────────────────
{
  # Bluetooth GUI manager (pairs with hardware.bluetooth.enable in hardware.nix)
  services.blueman.enable = true;

  # Storage / removable media
  services.devmon.enable  = true;
  services.gvfs.enable    = true;
  services.udisks2.enable = true;

  # Graphics tablet (Wacom, XP-Pen, Huion etc. via OpenTabletDriver)
  hardware.opentabletdriver.enable = true;
  hardware.uinput.enable           = true;  # required by OpenTabletDriver
}
