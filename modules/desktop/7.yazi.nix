{ pkgs, config, ... }:

# ── Yazi — terminal file manager ───────────────────────────────────────────────
# Super+N opens yazi in the default terminal (i3 + sway), Super+Shift+N opens
# nemo for GUI work (drag-and-drop etc.).
#
# In yazi:
#   Enter / o    open with the default app (xdg-open / $EDITOR / mpv)
#   O            choose an opener, including "Open with…"
#
# open-with <file>
#   fzf list of installed apps from .desktop entries. Apps registered for the
#   file's MIME type come first (★), then everything else. Launched detached
#   via gio, so it works from yazi and from any terminal.
#
# Shell: `y` starts yazi and cds the shell to wherever you quit it.
let
  user = config.profile.username;

  openWith = pkgs.writeShellScriptBin "open-with" ''
    shopt -s nullglob

    file="$1"
    if [ -z "$file" ] || [ ! -e "$file" ]; then
      echo "Usage: open-with <file>"
      exit 1
    fi
    file=$(realpath "$file")

    mime=$(${pkgs.file}/bin/file --mime-type -b "$file")
    group="''${mime%%/*}/*"

    # User entries first, so they shadow system entries with the same id
    IFS=: read -ra dirs <<< "''${XDG_DATA_HOME:-$HOME/.local/share}:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
    files=()
    for d in "''${dirs[@]}"; do
      files+=("$d"/applications/*.desktop)
    done
    if [ "''${#files[@]}" -eq 0 ]; then
      echo "open-with: no desktop entries found"
      exit 1
    fi

    # One row per app: rank  path  display  (rank 0 = registered for mime)
    choice=$(${pkgs.gawk}/bin/awk -v mime="$mime" -v group="$group" '
      function flush(  b, hit) {
        if (path == "" || hide || name == "") return
        b = path; sub(/.*\//, "", b)
        if (seen[b]++) return
        hit = index(mt, ";" mime ";") || index(mt, ";" group ";")
        printf "%d\t%s\t%s%s\n", (hit ? 0 : 1), path, (hit ? "★ " : "  "), name
      }
      FNR == 1 { flush(); path = FILENAME; name = ""; mt = ""; hide = 0; sec = 0 }
      /^\[/                             { sec = ($0 == "[Desktop Entry]"); next }
      sec && /^Name=/ && name == ""     { name = substr($0, 6) }
      sec && /^MimeType=/               { mt = ";" substr($0, 10) ";" }
      sec && /^(NoDisplay|Hidden)=true/ { hide = 1 }
      END { flush() }
    ' "''${files[@]}" \
      | sort -t $'\t' -k1,1n -k3,3f \
      | ${pkgs.fzf}/bin/fzf --delimiter='\t' --with-nth=3 \
          --prompt="open $(basename "$file") with> " \
          --header="★ = registered for $mime" \
          --reverse) || exit 0

    desktop=$(printf '%s' "$choice" | cut -f2)
    ${pkgs.util-linux}/bin/setsid -f \
      ${pkgs.glib}/bin/gio launch "$desktop" "$file" >/dev/null 2>&1
  '';

  openWithEntry = {
    run   = "${openWith}/bin/open-with \"$1\"";
    desc  = "Open with…";
    block = true;          # runs in yazi's terminal, so fzf gets a tty
    for   = "unix";
  };
in
{
  home-manager.users.${user} = {
    home.packages = [ openWith ];

    programs.yazi = {
      enable                = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      shellWrapperName      = "y";

      # Opener names match yazi's default rules (text → edit, images and
      # fallback → open, media → play), so "Open with…" shows up under O
      # for every file type.
      settings.opener = {
        open = [
          { run = "xdg-open \"$1\""; desc = "Open (default app)"; orphan = true; for = "unix"; }
          openWithEntry
        ];
        edit = [
          { run = "\${EDITOR:-nvim} \"$@\""; desc = "Edit"; block = true; for = "unix"; }
          openWithEntry
        ];
        play = [
          { run = "${pkgs.mpv}/bin/mpv --force-window \"$@\""; desc = "Play (mpv)"; orphan = true; for = "unix"; }
          openWithEntry
        ];
      };
    };
  };
}