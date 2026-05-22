{ pkgs, ... }:

# ── pavucontrol ────────────────────────────────────────────────────────────────
# PipeWire/PulseAudio volume mixer GUI.
# Opened on left-click of the Vol widget in desktop/bar.nix.
{
  environment.systemPackages = [ pkgs.pavucontrol ];
}
