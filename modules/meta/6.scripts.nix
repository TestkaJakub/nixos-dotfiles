{ lib, pkgs, config, ... }:

# ── Desktop scripts ────────────────────────────────────────────────────────────
# Desktop-specific binaries exposed via config.scripts.* so compositor and
# other desktop modules can reference their store paths directly.
#
# wallpaper-set    — set a wallpaper by path, or open a GUI picker (zenity)
#                    if no argument is given. Copies to collection/, updates
#                    the current symlink, applies via feh, runs hook if present.
# wallpaper-next   — advance to the next wallpaper in collection/, wrapping
#                    around. Foundation for future slideshow support.
# wallpaper-init   — apply current wallpaper on login, falling back to the
#                    store-backed default if no current wallpaper is set.
#                    Also writes fallback polybar colors if pywal hasn't run yet.
# theme-apply      — extract colors from wallpaper via pywal and apply to
#                    polybar, dunst, alacritty, wezterm, and terminals.
#
# Hook:
#   ~/.config/wallpaper/on-change is installed via home activation and calls
#   theme-apply automatically after every wallpaper change.
let
  user        = config.profile.username;
  defaultWall = config.meta.defaults.wallpaper;
  t           = config.theme;
  p           = t.palette;
  bg          = p.secondary;
  fg          = p.primary;
  accent      = t.functions.complement p.primary;
  dimmed      = t.functions.darken p.secondary 0.05;
  polybar     = pkgs.polybar.override { i3Support = true; pulseSupport = true; };
in
{
  options.scripts = {
    wallpaperSet = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Set a wallpaper by path or open a GUI picker.";
    };
    wallpaperNext = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Advance to the next wallpaper in collection, wrapping around.";
    };
    wallpaperInit = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Apply current wallpaper on login, falling back to store default.";
    };
    themeApply = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Extract colors from wallpaper via pywal and apply to all apps.";
    };
  };

  config = {
    scripts = {
      wallpaperSet = pkgs.writeShellScriptBin "wallpaper-set" ''
        set -e

        WALLPAPER_DIR="$HOME/.config/wallpaper"
        COLLECTION="$WALLPAPER_DIR/collection"
        CURRENT="$WALLPAPER_DIR/current"
        HOOK="$WALLPAPER_DIR/on-change"

        mkdir -p "$COLLECTION"

        # ── Pick image ────────────────────────────────────────────────────────
        if [ -n "$1" ]; then
          SOURCE="$1"
        else
          SOURCE=$(${pkgs.zenity}/bin/zenity \
            --file-selection \
            --title="Select wallpaper" \
            --filename="$HOME/data/Pictures/" \
            --file-filter="Images|*.jpg *.jpeg *.png *.bmp *.gif *.tiff *.webp" \
            2>/dev/null) || { echo "Cancelled."; exit 0; }

          if [ -z "$SOURCE" ]; then
            echo "No file selected."
            exit 0
          fi
        fi

        if [ ! -f "$SOURCE" ]; then
          echo "ERROR: File not found: $SOURCE"
          exit 1
        fi

        # ── Copy to collection ────────────────────────────────────────────────
        FILENAME=$(basename "$SOURCE")
        DEST="$COLLECTION/$FILENAME"

        if [ "$SOURCE" != "$DEST" ]; then
          cp "$SOURCE" "$DEST"
        fi

        # ── Update current symlink ────────────────────────────────────────────
        ln -sfT "$DEST" "$CURRENT"

        # ── Apply ─────────────────────────────────────────────────────────────
        ${pkgs.feh}/bin/feh --bg-scale "$CURRENT"

        echo "Wallpaper set to: $FILENAME"

        # ── Hook ──────────────────────────────────────────────────────────────
        if [ -x "$HOOK" ]; then
          "$HOOK" "$CURRENT"
        fi
      '';

      wallpaperNext = pkgs.writeShellScriptBin "wallpaper-next" ''
        set -e

        WALLPAPER_DIR="$HOME/.config/wallpaper"
        COLLECTION="$WALLPAPER_DIR/collection"
        CURRENT="$WALLPAPER_DIR/current"
        HOOK="$WALLPAPER_DIR/on-change"

        if [ ! -d "$COLLECTION" ] || [ -z "$(ls -A "$COLLECTION" 2>/dev/null)" ]; then
          echo "No wallpapers in collection. Use wallpaper-set to add some."
          exit 1
        fi

        # ── Build sorted list ─────────────────────────────────────────────────
        mapfile -t WALLS < <(find "$COLLECTION" -maxdepth 1 -type f | sort)
        COUNT=''${#WALLS[@]}

        if [ "$COUNT" -eq 0 ]; then
          echo "No wallpapers found in collection."
          exit 1
        fi

        # ── Find current index ────────────────────────────────────────────────
        CURRENT_TARGET=$(readlink -f "$CURRENT" 2>/dev/null || echo "")
        CURRENT_IDX=-1

        for i in "''${!WALLS[@]}"; do
          if [ "''${WALLS[$i]}" = "$CURRENT_TARGET" ]; then
            CURRENT_IDX=$i
            break
          fi
        done

        # ── Advance with wraparound ───────────────────────────────────────────
        NEXT_IDX=$(( (CURRENT_IDX + 1) % COUNT ))
        NEXT="''${WALLS[$NEXT_IDX]}"

        # ── Update current symlink ────────────────────────────────────────────
        ln -sfT "$NEXT" "$CURRENT"

        # ── Apply ─────────────────────────────────────────────────────────────
        ${pkgs.feh}/bin/feh --bg-scale "$CURRENT"

        echo "Wallpaper: $(basename "$NEXT") ($((NEXT_IDX + 1))/$COUNT)"

        # ── Hook ──────────────────────────────────────────────────────────────
        if [ -x "$HOOK" ]; then
          "$HOOK" "$CURRENT"
        fi
      '';

      wallpaperInit = pkgs.writeShellScriptBin "wallpaper-init" ''
        CURRENT="$HOME/.config/wallpaper/current"
        WAL_COLORS="$HOME/.cache/wal/colors-polybar.ini"

        # ── Write fallback polybar colors if pywal hasn't run yet ─────────────
        if [ ! -f "$WAL_COLORS" ]; then
          mkdir -p "$HOME/.cache/wal"
          cat > "$WAL_COLORS" << 'EOF'
[colors]
bg      = ${bg}
fg      = ${fg}
accent  = ${accent}
dimmed  = ${dimmed}
urgent  = #e06c75
EOF
        fi

        # ── Apply wallpaper ───────────────────────────────────────────────────
        if [ -L "$CURRENT" ] && [ -f "$CURRENT" ]; then
          ${pkgs.feh}/bin/feh --bg-scale "$CURRENT"
        else
          ${pkgs.feh}/bin/feh --bg-scale "${defaultWall}"
        fi
      '';

      themeApply = pkgs.writeShellScriptBin "theme-apply" ''
        set -e

        WALLPAPER="$1"

        if [ -z "$WALLPAPER" ]; then
          echo "Usage: theme-apply <wallpaper-path>"
          exit 1
        fi

        if [ ! -f "$WALLPAPER" ]; then
          echo "ERROR: File not found: $WALLPAPER"
          exit 1
        fi

        # ── Extract colors via pywal ──────────────────────────────────────────
        RESOLVED=$(readlink -f "$WALLPAPER")
        ${pkgs.pywal}/bin/wal -i "$RESOLVED" -n -q

        # ── Load extracted colors ─────────────────────────────────────────────
        . "$HOME/.cache/wal/colors.sh"

        # ── Write polybar colors ──────────────────────────────────────────────
        mkdir -p "$HOME/.cache/wal"
        cat > "$HOME/.cache/wal/colors-polybar.ini" << EOF
[colors]
bg      = $color0
fg      = $color7
accent  = $color1
dimmed  = $color8
urgent  = $color9
EOF

        # ── Restart polybar ───────────────────────────────────────────────────
        pkill polybar 2>/dev/null || true
        sleep 0.3
        ${polybar}/bin/polybar main &

        # ── Reload dunst ──────────────────────────────────────────────────────
        systemctl --user restart dunst 2>/dev/null || true

        # ── Write alacritty colors ────────────────────────────────────────────
        mkdir -p "$HOME/.config/alacritty"
        cat > "$HOME/.config/alacritty/colors.toml" << EOF
[colors.primary]
background = "$color0"
foreground = "$color7"

[colors.normal]
black   = "$color0"
red     = "$color1"
green   = "$color2"
yellow  = "$color3"
blue    = "$color4"
magenta = "$color5"
cyan    = "$color6"
white   = "$color7"

[colors.bright]
black   = "$color8"
red     = "$color9"
green   = "$color10"
yellow  = "$color11"
blue    = "$color12"
magenta = "$color13"
cyan    = "$color14"
white   = "$color15"
EOF

        # ── Write wezterm colors ──────────────────────────────────────────────
        mkdir -p "$HOME/.config/wezterm"
        cat > "$HOME/.config/wezterm/colors.toml" << EOF
[colors]
background = "$color0"
foreground = "$color7"

ansi = [
  "$color0", "$color1", "$color2", "$color3",
  "$color4", "$color5", "$color6", "$color7"
]

brights = [
  "$color8",  "$color9",  "$color10", "$color11",
  "$color12", "$color13", "$color14", "$color15"
]
EOF

        echo "Theme applied from: $(basename "$WALLPAPER")"
      '';
    };

    home-manager.users.${user} = { lib, ... }: {
      home.packages = [
        config.scripts.wallpaperSet
        config.scripts.wallpaperNext
        config.scripts.wallpaperInit
        config.scripts.themeApply
        pkgs.zenity
        pkgs.pywal
      ];

      # ── Install on-change hook ─────────────────────────────────────────────
      # Installed via activation so the store path of theme-apply is always
      # up to date after every rebuild.
      home.activation.installWallpaperHook =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.config/wallpaper"
          cat > "$HOME/.config/wallpaper/on-change" << 'EOF'
#!/bin/sh
${config.scripts.themeApply}/bin/theme-apply "$1"
EOF
          chmod +x "$HOME/.config/wallpaper/on-change"
        '';
    };
  };
}