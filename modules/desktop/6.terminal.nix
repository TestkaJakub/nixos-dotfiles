{ config, ... }:

# ── Terminals (WezTerm + Alacritty) ────────────────────────────────────────────
# Both are configured through home-manager so Stylix themes them: colors,
# font, font size (stylix.fonts.sizes.terminal) and opacity
# (stylix.opacity.terminal) all come from meta/7.stylix.nix.
# Only layout and behaviour live here.
#
# meta.defaults.terminal in 7.defaults.nix decides which one keybinds and
# xdg-open use.
let
  user = config.profile.username;
in
{
  home-manager.users.${user} = {

    # ── WezTerm ─────────────────────────────────────────────────────────────────
    # extraConfig must return a table; Stylix merges it over its own settings.
    programs.wezterm = {
      enable      = true;
      extraConfig = ''
        return {
          window_padding = { left = 14, right = 14, top = 14, bottom = 14 },
          hide_tab_bar_if_only_one_tab = true,
          enable_wayland = false,
          keys = {
            -- Alt+Enter is tai's "talk instead of run" key (shell/4.tai.nix)
            { key = 'Enter', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment },
          },
        }
      '';
    };

    # ── Alacritty ───────────────────────────────────────────────────────────────
    programs.alacritty = {
      enable = true;
      settings.window.padding = { x = 14; y = 14; };
    };
  };
}