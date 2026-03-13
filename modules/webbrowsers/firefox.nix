{ config, ... }:

# ── Firefox ────────────────────────────────────────────────────────────────────
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.programs.firefox.enable = true;
}
