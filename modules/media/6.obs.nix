{ pkgs, ... }:

# ── OBS Studio ─────────────────────────────────────────────────────────────────
# Screen recording / streaming.
#
# Capture sources by session:
#   i3 (X11)   → "Screen Capture (XSHM)" / "Window Capture (Xcomposite)"
#   sway       → "Wlroots output capture" (wlrobs, no portal needed)
#                or "Screen Capture (PipeWire)" via the xdg portal
#
# Encoding on the desktop (RX 9070 XT): pick "FFmpeg VAAPI H.264/HEVC/AV1"
# in Settings → Output. LIBVA_DRIVER_NAME=radeonsi is already set in
# system/6.graphics.nix.
#
# Virtual camera is off: 6.phone-webcam.nix already owns v4l2loopback
# (/dev/video10). See notes before enabling it.
{
  programs.obs-studio = {
    enable              = true;
    enableVirtualCamera = false;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs                       # native sway/wlroots screen capture
      obs-pipewire-audio-capture   # per-application audio sources
    ];
  };
}