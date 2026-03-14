{ pkgs, config, ... }:

# ── Terminal (WezTerm) ─────────────────────────────────────────────────────────
# Replaces Alacritty. WezTerm has built-in tabs, splits, and pixel graphics
# support (so fastfetch can show actual images).
# Config is via a Lua file at ~/.config/wezterm/wezterm.lua.
let
  user = config.profile.username;
  p    = config.theme.palette;
in
{
  home-manager.users.${user} = {
    home.packages = [ pkgs.wezterm ];

    xdg.configFile."wezterm/wezterm.lua".text = ''
      local wezterm = require 'wezterm'
      local config  = wezterm.config_builder()

      -- ── Appearance ────────────────────────────────────────────────────────
      config.font                = wezterm.font 'JetBrains Mono'
      config.font_size           = 12.0
      config.window_background_opacity = 0.9
      config.color_scheme        = 'Builtin Dark'

      config.colors = {
        foreground    = '${p.text}',
        background    = '${p.secondary}',
        cursor_bg     = '${p.termUser}',
        cursor_border = '${p.termUser}',
        cursor_fg     = '${p.secondary}',
        selection_bg  = '${p.termAccent}',
        selection_fg  = '${p.secondary}',
      }

      config.window_padding = {
        left = 10, right = 10, top = 10, bottom = 10,
      }

      -- ── Tab bar ───────────────────────────────────────────────────────────
      config.enable_tab_bar              = true
      config.use_fancy_tab_bar           = false
      config.tab_bar_at_bottom           = false
      config.hide_tab_bar_if_only_one_tab = true

      config.colors.tab_bar = {
        background = '${p.secondary}',
        active_tab = {
          bg_color  = '${p.termAccent}',
          fg_color  = '${p.secondary}',
        },
        inactive_tab = {
          bg_color = '${p.secondary}',
          fg_color = '${p.text}',
        },
        inactive_tab_hover = {
          bg_color = '${p.secondary}',
          fg_color = '${p.termUser}',
        },
        new_tab = {
          bg_color = '${p.secondary}',
          fg_color = '${p.text}',
        },
      }

      -- ── Keybinds ──────────────────────────────────────────────────────────
      config.keys = {
        -- Tabs
        { key = 't',          mods = 'SUPER',       action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
        { key = 'w',          mods = 'SUPER',       action = wezterm.action.CloseCurrentTab { confirm = false } },
        { key = 'LeftArrow',  mods = 'SUPER',       action = wezterm.action.ActivateTabRelative(-1) },
        { key = 'RightArrow', mods = 'SUPER',       action = wezterm.action.ActivateTabRelative(1) },
        -- Splits
        { key = 'd',          mods = 'SUPER',       action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'd',          mods = 'SUPER|SHIFT', action = wezterm.action.SplitVertical   { domain = 'CurrentPaneDomain' } },
        { key = 'LeftArrow',  mods = 'SUPER|SHIFT', action = wezterm.action.ActivatePaneDirection 'Left'  },
        { key = 'RightArrow', mods = 'SUPER|SHIFT', action = wezterm.action.ActivatePaneDirection 'Right' },
        { key = 'UpArrow',    mods = 'SUPER|SHIFT', action = wezterm.action.ActivatePaneDirection 'Up'    },
        { key = 'DownArrow',  mods = 'SUPER|SHIFT', action = wezterm.action.ActivatePaneDirection 'Down'  },
      }

      -- ── Shell ─────────────────────────────────────────────────────────────
      config.default_prog = { '${pkgs.fish}/bin/fish', '--init-command', 'fastfetch' }

      return config
    '';
  };
}
