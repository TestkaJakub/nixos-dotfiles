{ pkgs, config, lib, ... }:

# ── Bing "Photo of the Day" wallpaper ──────────────────────────────────────────
# The Spotlight-alike. Pulls Bing's daily curated image (which ships a
# location/description string), sets it live, notifies the location, and
# archives each day's image so a browsable collection builds up over time.
#
# Why this and not the feh pipeline in meta/6.scripts.nix:
#   feh is X11-only. Under Sway the background is owned by swaybg via the
#   `output * bg` line in 6.sway.nix, so wallpaper changes go through swaymsg.
#   This module talks swaymsg on Wayland and falls back to feh on X11 (i3),
#   so it's session-agnostic — prefix 6 = workstation + desktop, same as
#   6.sway.nix / 6.i3.nix.
#
# Command:
#   bing-wallpaper           fetch today's image (once/day), set it, notify
#   bing-wallpaper --force   refetch even if today's file already exists
#
# A systemd user timer refreshes daily and ~30s after login (Persistent=true
# catches up if the machine was off). The static `output * bg` in 6.sway.nix
# stays as the offline / pre-fetch fallback — keep it.
#
# Knobs: MARKET (caption language / image set) and the _UHD.jpg suffix
# (swap to _1920x1080.jpg for a lighter, panel-exact download).
let
  user   = config.profile.username;
  market = "en-US";   # en-US → English captions; try de-DE, ja-JP, etc.
in
{
  options.scripts.bingWallpaper = lib.mkOption {
    type        = lib.types.package;
    readOnly    = true;
    description = "Fetch Bing photo of the day, set it as wallpaper, notify location.";
  };

  config = {
    scripts.bingWallpaper = pkgs.writeShellScriptBin "bing-wallpaper" ''
      MARKET="${market}"
      CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/bing-wallpaper"
      ARCHIVE="$HOME/data/Pictures/BingWallpapers"
      mkdir -p "$CACHE" "$ARCHIVE"

      FORCE=0
      [ "''${1:-}" = "--force" ] && FORCE=1

      # ── swaymsg needs SWAYSOCK; a systemd timer won't have it in env ────────
      if [ -z "''${SWAYSOCK:-}" ]; then
        SWAYSOCK=$(find "/run/user/$(id -u)" -maxdepth 1 -name 'sway-ipc.*.sock' 2>/dev/null | head -n1)
        export SWAYSOCK
      fi

      TODAY=$(date +%F)
      IMG="$ARCHIVE/$TODAY.jpg"
      META="$CACHE/current.json"

      # ── Fetch metadata + image (skip if today's is already downloaded) ──────
      if [ "$FORCE" = 1 ] || [ ! -f "$IMG" ]; then
        JSON=$(${pkgs.curl}/bin/curl -fsSL --http1.1 --max-time 20 --retry 2 \
          "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=$MARKET") || {
            echo "bing-wallpaper: fetch failed, keeping current wallpaper" >&2
            exit 0
          }

        URLBASE=$(printf '%s' "$JSON"   | ${pkgs.jq}/bin/jq -r '.images[0].urlbase')
        COPYRIGHT=$(printf '%s' "$JSON" | ${pkgs.jq}/bin/jq -r '.images[0].copyright')
        TITLE=$(printf '%s' "$JSON"     | ${pkgs.jq}/bin/jq -r '.images[0].title // empty')
        CRLINK=$(printf '%s' "$JSON"    | ${pkgs.jq}/bin/jq -r '.images[0].copyrightlink // empty')

        URL="https://www.bing.com''${URLBASE}_UHD.jpg"   # 4K; swap to _1920x1080.jpg if you prefer

        if ! ${pkgs.curl}/bin/curl -fsSL --http1.1 --max-time 60 -o "$IMG.tmp" "$URL"; then
          echo "bing-wallpaper: image download failed" >&2
          rm -f "$IMG.tmp"
          exit 0
        fi
        mv "$IMG.tmp" "$IMG"

        # Persist caption for waybar / on-click
        ${pkgs.jq}/bin/jq -n \
          --arg title     "$TITLE" \
          --arg copyright "$COPYRIGHT" \
          --arg link      "$CRLINK" \
          --arg path      "$IMG" \
          '{title:$title, copyright:$copyright, link:$link, path:$path}' > "$META"

        # Plain-text caption (handy for a quick `cat` in waybar)
        printf '%s\n' "$COPYRIGHT" > "$CACHE/current.txt"

        # Notify the location (best-effort — dunst is already running)
        ${pkgs.libnotify}/bin/notify-send -u low -t 8000 \
          "🌍 ''${TITLE:-Bing Photo of the Day}" "$COPYRIGHT" || true
      fi

      # ── Apply for whatever session is running ───────────────────────────────
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        ${pkgs.sway}/bin/swaymsg output "*" bg "$IMG" fill >/dev/null 2>&1 \
          || echo "bing-wallpaper: swaymsg failed (SWAYSOCK not found?)" >&2
      elif [ -n "''${DISPLAY:-}" ]; then
        ${pkgs.feh}/bin/feh --bg-fill "$IMG"
      fi
    '';

    home-manager.users.${user} = {
      home.packages = [ config.scripts.bingWallpaper ];

      # ── Daily + on-login refresh ──────────────────────────────────────────
      systemd.user.services.bing-wallpaper = {
        Unit = {
          Description = "Set Bing photo of the day as wallpaper";
          After       = [ "graphical-session.target" ];
        };
        Service = {
          Type      = "oneshot";
          ExecStart = "${config.scripts.bingWallpaper}/bin/bing-wallpaper";
        };
      };

      systemd.user.timers.bing-wallpaper = {
        Unit.Description = "Daily Bing wallpaper refresh";
        Timer = {
          OnStartupSec = "30s";   # apply shortly after login
          OnCalendar   = "daily"; # and once a day thereafter
          Persistent   = true;    # catch up if the machine was off
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
