{ pkgs, config, ... }:

# ── Media ──────────────────────────────────────────────────────────────────────
# General media consumption and creation tools.
#
#   mpv          — video/audio player, camera feeds
#   anki         — spaced-repetition flashcards
#   swayimg      — Wayland image viewer
#   krita        — digital painting and illustration
#
# Tablet support (OpenTabletDriver, uinput) is in system/peripherals.nix.
# Wacom Xorg driver is installed system-wide because it is needed even under
# XWayland, so it belongs in environment.systemPackages rather than home.
let
  user = config.profile.username;
in
{
  environment.systemPackages = with pkgs; [
    krita
    xf86_input_wacom   # Xorg wacom driver (used even under XWayland)
    libinput           # input event library
  ];

  home-manager.users.${user}.home.packages = with pkgs; [
    mpv
  ];
}
