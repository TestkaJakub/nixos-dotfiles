{ config, ... }:

# ── Shared shell aliases ───────────────────────────────────────────────────────
# Single source of truth for aliases that are identical across bash and fish.
# aliasMap is defined once and assigned to both shells — no duplication.
let
  user = config.profile.username;

  aliasMap = {
    ll   = "ls -lah";
    dps  = "docker ps";
    dlog = "docker logs -f";
  };
in
{
  home-manager.users.${user} = {
    programs.bash.shellAliases = aliasMap;
    programs.fish.shellAliases = aliasMap;
  };
}
