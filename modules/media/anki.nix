{ pkgs, config, ... }:

# ── Anki ───────────────────────────────────────────────────────────────────────
# Spaced-repetition flashcard tool. Passive consumption of knowledge.
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.home.packages = [ pkgs.anki-bin ];
}
