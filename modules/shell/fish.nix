{ pkgs, config, ... }:

# ── Fish ───────────────────────────────────────────────────────────────────────
# Interactive shell. Bash is still used for all scripts (#!/bin/bash shebangs).
# All colors come from config.theme.palette so they stay in sync with bash and
# can be changed from theming.nix alone.
#
# programs.fish.enable must be set at system level so NixOS adds fish to
# /etc/shells, which is required for it to be a valid login shell.
#
# Common aliases (nmc, nhc, vnc) live in shell/aliases.nix and are merged in
# automatically — do not redeclare them here.
let
  user = config.profile.username;
  p    = config.theme.palette;
in
{
  programs.fish.enable = true;

  home-manager.users.${user} = {
    programs.fish = {
      enable = true;

      # Shell-specific alias only — common aliases come from shell/aliases.nix.
      shellAliases = {
        cd = "z";
      };

      # ── Prompt ────────────────────────────────────────────────────────────
      # Mirrors the bash PS1: user@host date path >
      # Fish prompts are functions, not strings, so we define fish_prompt here.
      functions.fish_prompt = ''
        set -l user_color   '${p.termUser}'
        set -l accent_color '${p.termAccent}'
        set -l date_str     (date '+%d-%m-%Y %H:%M:%S')

        echo -n (set_color $user_color)(whoami)(set_color $accent_color)@(set_color $user_color)(hostname)(set_color normal)
        echo -n " $date_str "
        echo -n (prompt_pwd)
        echo -n " "(set_color $accent_color)"fish >"(set_color normal)" "
      '';

      # ── Syntax highlighting ──────────────────────────────────────────────
      interactiveShellInit = ''
        set -g fish_greeting ""
        set -g fish_color_command        '${p.shellCommand}'
        set -g fish_color_error          '${p.shellError}'
        set -g fish_color_param          '${p.shellParam}'
        set -g fish_color_comment        '${p.shellComment}'
        set -g fish_color_autosuggestion '${p.shellAutosugg}'
        set -g fish_color_keyword        '${p.shellKeyword}'
        set -g fish_color_quote          '${p.shellString}'
        set -g fish_color_operator       '${p.shellOperator}'
        set -g fish_color_end            '${p.shellOperator}'
      '';
    };

    programs.zoxide = {
      enable                = true;
      enableFishIntegration = true;
    };
  };
}
