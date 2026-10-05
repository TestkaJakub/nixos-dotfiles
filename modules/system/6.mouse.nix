{ config, lib, ... }:

# ── Input ──────────────────────────────────────────────────────────────────────
# libinput pointer tuning — desktop only.
#
# accelProfile = "flat" disables pointer acceleration 100%: there is no
# velocity-based curve at all, so movement is pure 1:1. accelSpeed = "0" leaves
# the flat sensitivity neutral (no software scaling either) — the signal from
# the mouse is passed through untouched.
#
# Why this exists: the old NVIDIA config rendered the desktop at 2624x1476 and
# downscaled to the 1080p panel, so the cursor was shrunk ~0.73x on the way to
# the screen and felt slower/precise. At native 1920x1080 that shrink is gone,
# so raw pointer output is effectively ~37% faster. With acceleration off the
# fix for speed belongs at the source: drop a DPI stage on the mouse itself
# (the Model O- has onboard DPI stages) rather than scaling in software.
#
# If you'd rather slow it in software instead of touching the mouse, set a
# negative accelSpeed (e.g. "-0.4", range 0 … -1.0). That stays acceleration-
# free — flat has no curve — it just scales the flat response down.
#
# Applies to every pointer-class device (Glorious Model O-, HyperX, etc.), so
# there's no need to target individual xinput ids.
let
  isDesktop = config.profile.isRole [ "desktop" ];
in
{
  services.libinput = lib.mkIf isDesktop {
    enable = true;
    mouse = {
      accelProfile = "flat";   # acceleration fully disabled (1:1)
      accelSpeed   = "0";      # neutral flat sensitivity; go negative to slow in software
    };
  };
}