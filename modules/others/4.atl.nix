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

      mapfile -t pkgs < <(adb shell pm list packages | tr -d '\r' \
                          | sed 's/^package://' | grep -i -- "$filter" || true)
      if [ "''${#pkgs[@]}" -eq 0 ]; then
        echo "No installed package matches '$filter'. Is the phone connected (adb devices)?" >&2
        exit 1
      elif [ "''${#pkgs[@]}" -gt 1 ]; then
        echo "Several packages match '$filter' — pass a more specific filter:" >&2
        printf '  %s\n' "''${pkgs[@]}" >&2
        exit 1
      fi
      pkg="''${pkgs[0]}"
      echo "→ $pkg"

      tmp=$(mktemp -d)
      trap 'rm -rf "$tmp"' EXIT
      while read -r path; do
        adb pull "$path" "$tmp/" >/dev/null
      done < <(adb shell pm path "$pkg" | tr -d '\r' | sed 's/^package://')

      out="$dest/$id.apk"
      rm -f "$out"
      shopt -s nullglob
      parts=("$tmp"/*.apk)
      if [ "''${#parts[@]}" -eq 1 ]; then
        cp "''${parts[0]}" "$out"
      else
        echo "→ merging ''${#parts[@]} split APKs"
        APKEditor m -i "$tmp" -o "$out" >/dev/null
      fi
      echo "→ saved $out"

      # Icon (best effort): highest-density PNG from the manifest, else largest launcher PNG
      icon=$(aapt2 dump badging "$out" 2>/dev/null \
             | grep -oP "application-icon-\d+:'\K[^']+\.png" | tail -n1 || true)
      if [ -z "$icon" ]; then
        icon=$(unzip -Z -l "$out" 'res/*' 2>/dev/null | grep -i 'launcher.*\.png$' \
               | sort -k4 -n | tail -n1 | awk '{print $NF}' || true)
      fi
      if [ -n "$icon" ]; then
        unzip -p "$out" "$icon" > "$dest/$id.png" && echo "→ icon $dest/$id.png"
      else
        echo "→ no PNG icon found (adaptive icon?) — menu entry will use a generic one"
      fi

      atl-check "$out" || true
    '';
  };

  # atl-run <id> — launch; live output in a terminal, log file from the menu
  atl-run = pkgs.writeShellApplication {
    name          = "atl-run";
    runtimeInputs = [ pkgs.android-translation-layer pkgs.libnotify pkgs.coreutils ];
    text = ''
      id="''${1:?usage: atl-run <id>}"
      apk="${apkDir}/$id.apk"
      if [ ! -f "$apk" ]; then
        notify-send "ATL" "$apk not found — run: atl-pull $id"
        echo "$apk not found — run: atl-pull $id" >&2
        exit 1
      fi
      if [ -t 1 ]; then
        exec android-translation-layer "$apk"
      fi
      mkdir -p "${home}/.cache/atl"
      exec android-translation-layer "$apk" >"${home}/.cache/atl/$id.log" 2>&1
    '';
  };
in
{
  environment.systemPackages = [
    pkgs.android-translation-layer
    pkgs.android-tools   # adb (also pulled in by 4.vr.nix — harmless duplicate)
    pkgs.apkeditor       # standalone, for manual merges
    atl-check
    atl-pull
    atl-run
  ];

  systemd.tmpfiles.rules = [
    "d ${home}/Android      0755 ${user} ${user} -"
    "d ${apkDir}            0755 ${user} ${user} -"
  ];

  home-manager.users.${user}.xdg.desktopEntries = lib.mapAttrs (id: app: {
    name       = app.name;
    comment    = "Android app via ATL (experimental)";
    exec       = "atl-run ${id}";
    icon       = "${apkDir}/${id}.png";
    terminal   = false;
    categories = [ "AudioVideo" "Audio" ];
  }) apps;
}