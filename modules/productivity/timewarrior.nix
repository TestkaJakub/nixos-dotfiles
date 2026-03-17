{ pkgs, config, ... }:

# ── Timewarrior ────────────────────────────────────────────────────────────────
# Command-line time tracker, companion to Taskwarrior.
# Integrates automatically via the on-modify hook: running `task <id> start`
# starts a timew timer, and `task <id> stop` / `task <id> done` stops it.
#
# The hook script ships inside the timewarrior package itself at:
#   $out/share/doc/timew/ext/on-modify.timewarrior
# It is symlinked into ~/.config/task/hooks/ which is the hooks.location
# declared in productivity/taskwarrior.nix.
#
# Data follows XDG: ~/.local/share/timewarrior/
# Config: ~/.config/timewarrior/timewarrior.cfg
let
  user = config.profile.username;
in
{
  home-manager.users.${user} = {
    home.packages = [ pkgs.timewarrior ];

    # Hook — wires timew into every `task start` / `task stop` / `task done`
    xdg.configFile."task/hooks/on-modify.timewarrior" = {
      source    = "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
      executable = true;
    };

    # Timewarrior config
    xdg.configFile."timewarrior/timewarrior.cfg".text = ''
      # Keep data under XDG_DATA_HOME
      temp.db=~/.local/share/timewarrior

      # Behaviour
      confirmation=yes
      verbose=yes
    '';
  };
}
