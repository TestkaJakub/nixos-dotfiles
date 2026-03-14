{ pkgs, config, ... }:

# ── Fish ───────────────────────────────────────────────────────────────────────
# Interactive shell. Bash is still used for all scripts (they carry #!/bin/bash
# shebangs) — fish is for interactive use only.
#
# programs.fish.enable must be set at the system level so NixOS adds fish to
# /etc/shells, which is required for it to be a valid login shell.
let
  user = config.profile.username;
in
{
  programs.fish.enable = true;

  home-manager.users.${user} = {
    programs.fish = {
      enable = true;

      shellAliases = {
        nmc = "sudo nvim ~/nixos-dotfiles/flake.nix";
        nhc = "sudo nvim ~/nixos-dotfiles/modules";
        vnc = "wayvnc 192.168.0.16 5900";
        cd  = "z";                                     # zoxide smart cd
      };
    };

    programs.zoxide = {
      enable                = true;
      enableFishIntegration = true;
    };
  };
}
