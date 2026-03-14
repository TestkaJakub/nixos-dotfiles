{ config, ... }:

# ── Shared shell aliases ───────────────────────────────────────────────────────
# Single source of truth for aliases that are identical across bash and fish.
# Both shell modules merge from config.meta.shellAliases rather than
# duplicating the list.
#
# Shell-specific aliases (e.g. fish's cd = "z") remain in their own modules.
let
  user = config.profile.username;
in
{
  home-manager.users.${user} = {
    # Expose as a home-manager shellAliases attrset that both shells can merge.
    programs.bash.shellAliases = {
      nmc = "sudo nvim ~/nixos-dotfiles/flake.nix";
      nhc = "sudo nvim ~/nixos-dotfiles/modules";
      vnc = "wayvnc 192.168.0.16 5900";
    };

    programs.fish.shellAliases = {
      nmc = "sudo nvim ~/nixos-dotfiles/flake.nix";
      nhc = "sudo nvim ~/nixos-dotfiles/modules";
      vnc = "wayvnc 192.168.0.16 5900";
    };
  };
}
