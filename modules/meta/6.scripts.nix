{ lib, pkgs, config, ... }:

# ── Desktop scripts ────────────────────────────────────────────────────────────
# Desktop-specific binaries exposed via config.scripts.* so compositor and
# other desktop modules can reference their store paths directly.
#
# wallpaper-set    — set a wallpaper by path, or open a GUI picker (zenity)
#                    if no argument is given. Copies to collection/, updates
#                    the current symlink, applies via feh, runs hook if present.
# wallpaper-next   — advance to the next wallpaper in collection/, wrapping
#                    around.
# wallpaper-init   — apply current wallpaper on login, falling back to the
#                    store-backed default if no current wallpaper is set.
#
# Colors no longer follow the wallpaper — the palette lives in Stylix
# (meta/7.stylix.nix). The old pywal / theme-apply pipeline is gone.
#
# Hook (optional, yours to create):
#   ~/.config/wallpaper/on-change is run with the new wallpaper path after
#   every change, if it exists and is executable.
let
  user        = config.profile.username;
  defaultWall = config.meta.defaults.wallpaper;
  feh         = "${pkgs.feh}/bin/feh";
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

        # ── Update current symlink + apply ────────────────────────────────────
        ln -sfT "$DEST" "$CURRENT"
        ${feh} --bg-scale "$CURRENT"

        echo "Wallpaper set to: $FILENAME"

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

        mapfile -t WALLS < <(find "$COLLECTION" -maxdepth 1 -type f | sort)
        COUNT=''${#WALLS[@]}

        if [ "$COUNT" -eq 0 ]; then
          echo "No wallpapers found in collection."
          exit 1
        fi

        CURRENT_TARGET=$(readlink -f "$CURRENT" 2>/dev/null || echo "")
        CURRENT_IDX=-1

        for i in "''${!WALLS[@]}"; do
          if [ "''${WALLS[$i]}" = "$CURRENT_TARGET" ]; then
            CURRENT_IDX=$i
            break
          fi
        done

        NEXT_IDX=$(( (CURRENT_IDX + 1) % COUNT ))
        NEXT="''${WALLS[$NEXT_IDX]}"

        ln -sfT "$NEXT" "$CURRENT"
        ${feh} --bg-scale "$CURRENT"

        echo "Wallpaper: $(basename "$NEXT") ($((NEXT_IDX + 1))/$COUNT)"

        if [ -x "$HOOK" ]; then
          "$HOOK" "$CURRENT"
        fi
      '';

      wallpaperInit = pkgs.writeShellScriptBin "wallpaper-init" ''
        CURRENT="$HOME/.config/wallpaper/current"

        if [ -L "$CURRENT" ] && [ -f "$CURRENT" ]; then
          ${feh} --bg-scale "$CURRENT"
        else
          ${feh} --bg-scale "${defaultWall}"
        fi
      '';
    };

    home-manager.users.${user} = { lib, ... }: {
      home.packages = [
        config.scripts.wallpaperSet
        config.scripts.wallpaperNext
        config.scripts.wallpaperInit
        pkgs.zenity
      ];

      # The old activation installed an on-change hook that called theme-apply.
      # Remove it so wallpaper-set/next don't run a dead store path.
      home.activation.removeOldWallpaperHook =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          hook="$HOME/.config/wallpaper/on-change"
          if [ -f "$hook" ] && ${pkgs.gnugrep}/bin/grep -q theme-apply "$hook"; then
            rm -f "$hook"
          fi
        '';
    };
  };
}