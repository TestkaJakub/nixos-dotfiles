{ pkgs, config, ... }:

# ── Screenshots ────────────────────────────────────────────────────────────────
# Two binaries: screenshot-region (select area) and screenshot-full (all outputs).
# Both save to ~/Pictures/Screenshots/YYYY-MM/, copy to clipboard, and notify.
# Keybinds are wired in desktop/compositor.nix (super+PrintScreen).
#
# grim, slurp, wl-clipboard, and libnotify are declared here rather than
# bash.nix because screenshots are a desktop concern, not a shell one.
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
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
      grim -g "$(slurp)" "$file"
      ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
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
      grim "$file"
      ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
      ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
    '')
  ];
}
