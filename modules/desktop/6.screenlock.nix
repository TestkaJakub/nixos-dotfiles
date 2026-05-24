{ pkgs, config, ... }:

# ── Hyprlock — screen locker ───────────────────────────────────────────────────
# Reads: config.theme.palette
#        config.profile.username
#        config.meta.defaults.wallpaper
let
  user = config.profile.username;
  t    = config.theme;
  bg   = t.palette.secondary;
  fg   = t.functions.textcolor t.palette.secondary;
  accent = t.palette.primary;
in
{
  home-manager.users.${user} = {
    home.packages = [ pkgs.hyprlock ];

    xdg.configFile."hypr/hyprlock.conf".text = ''
      background {
        monitor =
        path = ${config.meta.defaults.wallpaper}
        blur_passes = 3
        blur_size = 7
        brightness = 0.5
      }

      input-field {
        monitor =
        size = 300, 50
        outline_thickness = 2
        dots_size = 0.2
        dots_spacing = 0.2
        outer_color = rgb(${builtins.substring 1 6 accent})
        inner_color = rgb(${builtins.substring 1 6 bg})
        font_color = rgb(${builtins.substring 1 6 fg})
        fade_on_empty = true
        placeholder_text = <i>Password...</i>
        hide_input = false
        position = 0, -100
        halign = center
        valign = center
      }

      label {
        monitor =
        text = cmd[update:1000] echo "<b>$(date +"%H:%M")</b>"
        color = rgb(${builtins.substring 1 6 fg})
        font_size = 64
        font_family = JetBrains Mono
        position = 0, 100
        halign = center
        valign = center
      }
    '';
  };
}
