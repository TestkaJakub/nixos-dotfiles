{ lib, pkgs, config, ... }:

# ── Desktop scripts ────────────────────────────────────────────────────────────
# The wallpaper drives the whole theme: Stylix generates the palette from
# modules/meta/wallpapers/current.jpg at build time (see 7.stylix.nix).
#
# set-theme [image]   — pick a wallpaper (zenity picker if no argument),
#                       copy it into the repo as current.jpg, run nrs so Stylix
#                       regenerates the palette, then reload i3/sway.
# wallpaper-init      — apply the wallpaper on login (i3 / feh).
#                       sway sets it itself via `output * bg`.
let
  user      = config.profile.username;
  wallpaper = config.meta.defaults.wallpaper;
  nrs       = "${config.scripts.nrs}/bin/nrs";
in
{
  options.scripts = {
    wallpaperInit = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Apply the Stylix wallpaper on login (X11).";
    };
    setTheme = lib.mkOption {
      type        = lib.types.package;
      readOnly    = true;
      description = "Set a wallpaper, regenerate the Stylix palette from it, and rebuild.";
    };
  };

  config = {
    scripts = {
      wallpaperInit = pkgs.writeShellScriptBin "wallpaper-init" ''
        ${pkgs.feh}/bin/feh --no-fehbg --bg-fill "${wallpaper}"
      '';

      setTheme = pkgs.writeShellScriptBin "set-theme" ''
        set -e

        FLAKE="$HOME/nixos-dotfiles"
        DEST="$FLAKE/modules/meta/wallpapers/current.jpg"

        # ── Pick image ────────────────────────────────────────────────────────
        if [ -n "$1" ]; then
          SOURCE="$1"
        else
          SOURCE=$(${pkgs.zenity}/bin/zenity \
            --file-selection \
            --title="Pick a wallpaper — the theme will follow it" \
            --filename="$HOME/data/Pictures/" \
            --file-filter="Images|*.jpg *.jpeg *.png *.webp *.bmp *.tiff" \
            2>/dev/null) || { echo "Cancelled."; exit 0; }
        fi

        if [ ! -f "$SOURCE" ]; then
          echo "set-theme: file not found: $SOURCE"
          exit 1
        fi

        # ── Copy into the repo as JPEG (one fixed name Stylix points at) ──────
        ${pkgs.imagemagick}/bin/magick "$SOURCE" -strip -quality 92 "$DEST"
        echo "Wallpaper: $(basename "$SOURCE") → modules/meta/wallpapers/current.jpg"
        echo "Rebuilding — Stylix regenerates the palette from it..."
        echo ""

        # nrs commits the new image and switches
        ${nrs}

        # ── Reload the running session so bar/borders/wallpaper update ────────
        if [ -n "''${SWAYSOCK:-}" ]; then
          ${pkgs.sway}/bin/swaymsg reload >/dev/null
        elif [ -n "''${DISPLAY:-}" ]; then
          ${pkgs.i3}/bin/i3-msg restart >/dev/null 2>&1 || true
        fi

        echo ""
        echo "Theme applied. Open new terminals (or run: exec fish) to see the new colors."
      '';
    };

    home-manager.users.${user} = { lib, ... }: {
      home.packages = [
        config.scripts.wallpaperInit
        config.scripts.setTheme
        pkgs.zenity
      ];

      # Remove the old on-change hook (it called theme-apply, which is gone).
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