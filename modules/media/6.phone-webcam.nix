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
#   phonecam     queries the phone, lets you pick camera + size + fps via fzf
#   Ctrl+C       stop (the device stays, it just goes blank)
#
# Bitrate scales with the chosen mode (~0.15 bit/pixel, 4–80 Mbps).
# Above 1080p the stream switches to H.265, since phone H.264 encoders often
# refuse 4K. Override with PHONECAM_CODEC=h264|h265|av1.
let
  videoNr = "10";
  device  = "/dev/video${videoNr}";

  awk    = "${pkgs.gawk}/bin/awk";
  fzf    = "${pkgs.fzf}/bin/fzf";
  scrcpy = "${pkgs.scrcpy}/bin/scrcpy";

  phonecam = pkgs.writeShellScriptBin "phonecam" ''
    set -o pipefail

    if [ ! -e "${device}" ]; then
      echo "phonecam: ${device} missing — run: sudo modprobe v4l2loopback"
      exit 1
    fi

    echo "Querying phone cameras..."
    raw=$(${scrcpy} --list-camera-sizes 2>&1) || {
      echo "$raw"
      echo "phonecam: could not query the phone (connected? USB debugging on?)"
      exit 1
    }

    # ── Parse: one row per (camera, size), tab-separated ──────────────────────
    # id  w  h  fpslist  highspeed  <display text>
    rows=$(printf '%s\n' "$raw" | ${awk} '
      function gcd(a, b,  t) { while (b) { t = b; b = a % b; a = t } return a }
      function ratio(w, h,  g) {
        g = gcd(w, h)
        if (w / g <= 21 && h / g <= 21) return (w / g) ":" (h / g)
        return sprintf("%.2f:1", w / h)
      }
      /--camera-id=/ {
        match($0, /--camera-id=([0-9]+)/, a); id = a[1]
        match($0, /\(([a-z]+),/, b);         facing = b[1]
        match($0, /fps=\[([^]]*)\]/, c);     fps = c[1]; gsub(/ /, "", fps)
        hs = 0; next
      }
      /High speed capture/ { hs = 1; next }
      /^[[:space:]]+- [0-9]+x[0-9]+/ {
        match($0, /([0-9]+)x([0-9]+)/, s)
        f = fps
        if (hs) { match($0, /fps=\[([^]]*)\]/, h); f = h[1]; gsub(/ /, "", f) }
        key = id SUBSEP s[1] SUBSEP s[2] SUBSEP hs
        if (seen[key]++) next
        printf "%s\t%s\t%s\t%s\t%s\t%-6s %5sx%-5s %-8s %5.1f MP   fps %s%s\n",
          id, s[1], s[2], f, hs,
          facing, s[1], s[2], ratio(s[1], s[2]), s[1] * s[2] / 1e6,
          f, (hs ? "   [high-speed]" : "")
      }
    ')

    if [ -z "$rows" ]; then
      echo "$raw"
      echo "phonecam: no camera sizes found in scrcpy output"
      exit 1
    fi

    # ── Pick camera + size ────────────────────────────────────────────────────
    choice=$(printf '%s\n' "$rows" | ${fzf} \
      --delimiter='\t' --with-nth=6 \
      --prompt='camera> ' \
      --header='facing  resolution  ratio  megapixels  fps' \
      --height=60% --reverse) || { echo "Cancelled."; exit 0; }

    IFS=$'\t' read -r id w h fpslist hs _ <<< "$choice"

    # ── Pick fps (auto if only one option) ────────────────────────────────────
    fpsopts=$(printf '%s\n' "$fpslist" | tr ',' '\n' | sort -rn)
    if [ "$(printf '%s\n' "$fpsopts" | wc -l)" -gt 1 ]; then
      fps=$(printf '%s\n' "$fpsopts" | ${fzf} \
        --prompt='fps> ' --height=30% --reverse) || { echo "Cancelled."; exit 0; }
    else
      fps="$fpsopts"
    fi

    # ── Derive bitrate + codec ────────────────────────────────────────────────
    bitrate=$(( w * h * fps * 15 / 100 ))
    [ "$bitrate" -lt 4000000 ]  && bitrate=4000000
    [ "$bitrate" -gt 80000000 ] && bitrate=80000000

    if [ -n "$PHONECAM_CODEC" ]; then
      codec="$PHONECAM_CODEC"
    elif [ $(( w * h )) -gt $(( 1920 * 1080 )) ]; then
      codec=h265
    else
      codec=h264
    fi

    extra=()
    [ "$hs" = 1 ] && extra+=(--camera-high-speed)

    echo "Camera $id  ''${w}x''${h} @ ''${fps}fps  $codec  $(( bitrate / 1000000 )) Mbps  → ${device}"

    exec ${scrcpy} \
      --video-source=camera \
      --camera-id="$id" \
      --camera-size="''${w}x''${h}" \
      --camera-fps="$fps" \
      --video-codec="$codec" \
      --video-bit-rate="$bitrate" \
      "''${extra[@]}" \
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