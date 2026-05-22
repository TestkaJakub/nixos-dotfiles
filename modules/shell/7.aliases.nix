{ config, ... }:

# ── Shared shell aliases ───────────────────────────────────────────────────────
# Single source of truth for aliases that are identical across bash and fish.
# aliasMap is defined once and assigned to both shells — no duplication.
#
# Shell-specific aliases (e.g. fish's cd = "z", bash's cd = "z" via zoxide.nix)
# remain in their own modules.
let
  user = config.profile.username;

  aliasMap = {
    nmc = "sudo nvim ~/nixos-dotfiles/flake.nix";
    nhc = "sudo nvim ~/nixos-dotfiles/modules";
    vnc = "wayvnc 192.168.0.16 5900";
  };
in
{
  home-manager.users.${user} = {
    programs.bash.shellAliases = aliasMap;
    programs.fish.shellAliases = aliasMap;
  };
}
