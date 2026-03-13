{ config, ... }:

# ── Mako — notification daemon ─────────────────────────────────────────────────
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.services.mako = {
    enable   = true;
    settings = {
      default-timeout = 5000;
      border-radius   = 4;
    };
  };
}
