{ pkgs, config, ... }:

# ── cliphist — clipboard manager ──────────────────────────────────────────────
# Stores clipboard history and integrates with fuzzel for retrieval.
# super+shift+v opens the clipboard history picker.
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.home.packages = with pkgs; [
    cliphist
    wl-clipboard
  ];
}
