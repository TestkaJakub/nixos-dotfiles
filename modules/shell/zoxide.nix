{ config, ... }:

# ── Zoxide ─────────────────────────────────────────────────────────────────────
# Smart cd replacement. Integrates with bash via initExtra hook.
# The cd alias is declared here rather than in bash.nix so that disabling
# zoxide also removes the alias cleanly.
let
  user = config.profile.username;
in
{
  home-manager.users.${user} = {
    programs.zoxide = {
      enable                = true;
      enableBashIntegration = true;
    };

    programs.bash.shellAliases.cd = "z";
  };
}
