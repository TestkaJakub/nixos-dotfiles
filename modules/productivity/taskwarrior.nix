{ pkgs, config, ... }:

# ── Taskwarrior ────────────────────────────────────────────────────────────────
# CLI task manager. Config follows XDG: ~/.config/task/taskrc
# Data is kept at ~/.local/share/task so the home dir stays clean.
#
# The editor key picks up config.meta.defaults.editor so it stays in sync
# with the rest of the system (currently micro).
#
# Placed in productivity/ alongside obsidian and libreoffice.
let
  user = config.profile.username;
  editor = config.meta.defaults.editor;
in
{
  home-manager.users.${user} = {
    home.packages = [ pkgs.taskwarrior3 ];

    xdg.configFile."task/taskrc".text = ''
      # Data & hooks
      data.location=~/.local/share/task
      hooks.location=~/.config/task/hooks

      # Editor — mirrors meta.defaults.editor
      editor=${editor}

      # Behaviour
      confirmation=yes
      verbose=blank,header,footnote,label,new-id

      # Colours — keep it readable in the dark terminal
      color=on
    '';
  };
}
