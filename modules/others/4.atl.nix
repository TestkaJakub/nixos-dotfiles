{ pkgs, lib, config, ... }:

# ── Android Translation Layer (ATL) ────────────────────────────────────────────
# Runs Android APKs as native GTK4 windows — no Android system/container
# underneath (Wine-style API translation). Very experimental: apps that need
# Google Play Services or Widevine DRM will most likely not work.
#
# Workflow:
#   1. Phone: enable USB debugging, plug in.
#   2. atl-pull woblink           → pulls + merges split APKs into ~/Android/apks/woblink.apk,
#                                   extracts icon, reports CPU architecture
#   3. Launch "Woblink" from fuzzel (desktop entry generated below), or
#      atl-run woblink in a terminal to see the live log.
#   Logs from menu launches: ~/.cache/atl/<id>.log
#
# Add/remove apps in `apps` below. Key = file id, `filter` = substring of the
# Android package name used by atl-pull to find it on the phone.
#
# Reads: config.profile.{username, homeDirectory}
let
  user   = config.profile.username;
  home   = config.profile.homeDirectory;
  apkDir = "${home}/Android/apks";

  apps = {
    woblink   = { name = "Woblink";   filter = "woblink";   };
    audioteka = { name = "Audioteka"; filter = "audioteka"; };
    bookbeat  = { name = "BookBeat";  filter = "bookbeat";  };
  };

  # atl-check <file.apk> — can this APK run on this machine's CPU?
  atl-check = pkgs.writeShellApplication {
    name          = "atl-check";
    runtimeInputs = [ pkgs.unzip pkgs.coreutils pkgs.gnugrep ];
    text = ''
      apk="''${1:?usage: atl-check <file.apk>}"
      abis=$(unzip -Z1 "$apk" | grep '^lib/' | cut -d/ -f2 | sort -u || true)
      if [ -z "$abis" ]; then
        echo "✓ $apk: no native libs (pure Java/Kotlin) — good chance ATL can run it"
      elif grep -qx 'x86_64' <<<"$abis"; then
        echo "✓ $apk: ships x86_64 libs — architecture OK"
      else
        echo "✗ $apk: native libs only for: $(tr '\n' ' ' <<<"$abis")"
        echo "  ATL does no CPU translation, so this won't run on x86_64."
        exit 1
      fi
    '';
  };

  # atl-pull <id> [filter] — pull an installed app off the phone via adb
  atl-pull = pkgs.writeShellApplication {
    name          = "atl-pull";
    runtimeInputs = [ pkgs.android-tools pkgs.apkeditor pkgs.aapt pkgs.unzip
                      pkgs.coreutils pkgs.gnugrep pkgs.gnused atl-check ];
    text = ''
      id="''${1:?usage: atl-pull <id> [package-filter]}"
      filter="''${2:-$id}"
      dest="${apkDir}"
      mkdir -p "$dest"

      mapfile -t pkgs < <(adb shell pm list packages | tr -d '\r'