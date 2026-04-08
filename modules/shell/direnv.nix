{ config, ... }:

# ── direnv ─────────────────────────────────────────────────────────────────────
# Auto-loads .envrc when cd-ing into a project directory.
# nix-direnv caches flake evaluations so entering your node/python dev shells
# is instant rather than re-evaluating the flake every time.
#
# Does NOT affect container environmentFiles or any NixOS-level secrets —
# it only activates in directories that contain a .envrc file.
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.programs.direnv = {
    enable                = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    nix-direnv.enable     = true;
  };
}
