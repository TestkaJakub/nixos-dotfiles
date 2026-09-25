# modules/media/6.phone-webcam.nix
{ pkgs, config, ... }:

# ── Phone as webcam (scrcpy → v4l2loopback) ────────────────────────────────────
# v4l2loopback creates a virtual /dev/video10 ("Phone Webcam"). scrcpy captures
# the phone's camera (Android 12+) and writes frames into it, so any app sees
# a regular webcam.
#
# exclusive_caps=1 is required for Chromium/Firefox-based browsers (incl.
# LibreWolf / Brave) to detect the device as a capture source.
#
# Usage:
#   phonecam            back camera
#   phonecam front      selfie camera
#   Ctrl+C              stop (the device stays, it just goes blank)
#
# List what your phone supports:
#   scrcpy --list-cameras
#   scrcpy --list-camera-sizes
let
  videoNr = "10";
  device  = "/dev/video${videoNr}";

  phonecam = pkgs.writeShellScriptBin "phonecam" ''
    facing="''${1:-back}"
    case "$facing" in
      back|front) ;;
      *) echo "Usage: phonecam [back|front]"; exit 1 ;;
    esac

    if [ ! -e "${device}" ]; then
      echo "phonecam: ${device} missing — run: sudo modprobe v4l2loopback"
      exit 1
    fi

    exec ${pkgs.scrcpy}/bin/scrcpy \
      --video-source=camera \
      --camera-facing="$facing" \
      --max-size=1920 \
      --no-audio \
      --no-playback \
      --v4l2-sink=${device}
  '';
in
{
  # Uses config.boot.kernelPackages, so it follows linuxPackages_latest on desktop
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules       = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=${videoNr} card_label="Phone Webcam" exclusive_caps=1
  '';

  environment.systemPackages = [
    phonecam
    pkgs.v4l-utils   # v4l2-ctl --list-devices for debugging
  ];
}