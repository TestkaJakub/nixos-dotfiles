{ pkgs, config, inputs, ... }:

# ── Terminal (Alacritty + Wezterm) ────────────────────────────────────────────
# Alacritty: wrapped via lassulus/wrappers with opacity set to 0.85.
# Wezterm:   configured via wezterm.lua (wrappers doesn't expose opacity).
#
# Both terminals are available. meta.defaults.terminal in defaults.nix
# determines which one keybinds / xdg-open use.
# To switch the default, change meta.defaults.terminal / terminalPackage
# / terminalRun in modules/meta/defaults.nix.
let
  user = config.profile.username;

  alacrittyPkg = (inputs.wrappers.wrapperModules.alacritty.apply {
    pkgs = pkgs // { lndir = pkgs.xorg.lndir; };
    settings = {
      window = {
        opacity = 0.85;
        padding = { x = 14; y = 14; };
      };
      font = {
        size = 16;
        normal = {
          family = "JetBrains Mono";
          style  = "Regular";
        };
      };
    };
  }).wrapper;
in
{
  home-manager.users.${user} = {
    home.packages = [ alacrittyPkg pkgs.wezterm ];

    # Wezterm config — opacity is not exposed by the wrappers input so we
    # configure it directly via wezterm.lua.
    xdg.configFile."wezterm/wezterm.lua".text = ''
      local wezterm = require 'wezterm'

      return {
        -- Semi-transparent background
        window_background_opacity = 0.85,

        -- Match Alacritty font choice
        font = wezterm.font('JetBrains Mono'),
        font_size = 12.0,

        -- Padding mirrors Alacritty
        window_padding = {
          left   = 10,
          right  = 10,
          top    = 10,
          bottom = 10,
        },

        -- Hide the tab bar when only one tab is open
        hide_tab_bar_if_only_one_tab = true,

        enable_wayland = false,
      }
    '';
  };
}
