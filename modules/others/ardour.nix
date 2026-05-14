{ pkgs, ... }:

# ── Ardour ─────────────────────────────────────────────────────────────────────
# Professional open-source DAW for recording, editing, and mixing.
# Requires PipeWire (audio.nix) — no extra config needed on this system.
#
# First launch: Ardour will ask you to select an audio backend.
# Choose ALSA or PipeWire (via JACK bridge if needed).
#
# For low-latency JACK support, consider enabling services.jack in audio.nix.
{
  environment.systemPackages = with pkgs; [
    ardour
    qjackctl   # GUI for JACK routing/connection management
  ];
}
