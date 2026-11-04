# modules/shell/7.eza.nix
{ pkgs, config, ... }:

# ── eza ────────────────────────────────────────────────────────────────────────
# Modern ls: colours, git status column, Nerd Font icons (Stylix monospace is
# JetBrainsMono Nerd Font). Plain `ls` is left alone: its sort flags differ
# from eza's, so scripts and copied commands keep working.
#
# The ll alias lives here, not in shell/aliases.nix, so removing this
# file brings back plain `ls -lah`.
let
  user = config.profile.username;

  eza  = "eza --icons=auto --group-directories-first";
  aliases = {
    ll = "${eza} -la --git";             # long list, hidden files, git status
    lt = "${eza} --tree --level=2";      # 2-level tree
    la = "${eza} -a";                    # short list incl. hidden
  };
in
{
  home-manager.users.${user} = {
    home.packages = [ pkgs.eza ];

    programs.bash.shellAliases = aliases;
    programs.fish.shellAliases = aliases;
  };
}