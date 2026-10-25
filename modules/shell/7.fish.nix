{ config, ... }:

# ── Fish ───────────────────────────────────────────────────────────────────────
# Interactive shell. Bash is still used for all scripts (#!/bin/bash shebangs).
#
# Colors come from Stylix (meta/7.stylix.nix):
#   - syntax highlighting: Stylix's fish target (base16-fish)
#   - prompt:              config.lib.stylix.colors, below
#
# programs.fish.enable must be set at system level so NixOS adds fish to
# /etc/shells, which is required for it to be a valid login shell.
#
# Common aliases live in shell/aliases.nix and are merged in automatically —
# do not redeclare them here.
let
  user = config.profile.username;
  c    = config.lib.stylix.colors.withHashtag;
in
{
  programs.fish.enable = true;

  home-manager.users.${user} = {
    programs.fish = {
      enable = true;

      # Shell-specific alias only — common aliases come from shell/aliases.nix.
      shellAliases = {};

      # ── Prompt ────────────────────────────────────────────────────────────
      # Mirrors the bash PS1: user@host date path >
      functions.fish_prompt = ''
        set -l accent '${c.base0D}'
        set -l second '${c.base0E}'
        set -l dimmed '${c.base03}'
        set -l date_str (date '+%d-%m-%Y %H:%M:%S')

        echo -n (set_color $accent)(whoami)(set_color $second)@(set_color $accent)(hostname)(set_color normal)
        echo -n (set_color $dimmed)" $date_str "(set_color normal)
        echo -n (prompt_pwd)
        echo -n " "(set_color $second)"fish >"(set_color normal)" "
      '';

      interactiveShellInit = ''
        set -g fish_greeting ""
      '';
    };
  };
}