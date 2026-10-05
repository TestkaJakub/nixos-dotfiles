{ pkgs, config, ... }:

# ── Screenshots ────────────────────────────────────────────────────────────────
# Two binaries: screenshot-region (select area) and screenshot-full (all outputs).
# Both save to ~/Pictures/Screenshots/YYYY-MM/, copy to clipboard, and notify.
# X11 tools: scrot (capture), xclip (clipboard), libnotify (notification).
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.home.packages = with pkgs; [
    scrot
    xclip
    libnotify

    (writeShellScriptBin "screenshot-region" ''
      dir="$HOME/Pictures/Screenshots/$(date +%Y-%m)"
      mkdir -p "$dir"
      base="$(date +%d_%H.%M.%S)"
      file="$dir/$base.png"
      n=1
      while [ -e "$file" ]; do
        file="$dir/$base.$n.png"
        n=$(( n + 1 ))
      done
      ${pkgs.scrot}/bin/scrot --select "$file"
      ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png < "$file"
      ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
    '')

    (writeShellScriptBin "screenshot-full" ''
      dir="$HOME/Pictures/Screenshots/$(date +%Y-%m)"
      mkdir -p "$dir"
      base="$(date +%d_%H.%M.%S)"
      file="$dir/$base.png"
      n=1
      while [ -e "$file" ]; do
        file="$dir/$base.$n.png"
        n=$(( n + 1 ))
      done
      ${pkgs.scrot}/bin/scrot "$file"
      ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png < "$file"
      ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
    '')
  ];
}