{ pkgs, config, lib, ... }:

# ── i3 desktop ─────────────────────────────────────────────────────────────────
# WM:          i3 (floating by default, Super+Shift+Space to toggle tiling)
# Bar:         polybar
# Launcher:    rofi
# Compositor:  picom
# Wallpaper:   feh via wallpaper-init
# DM:          LightDM (unchanged)
#
# Colors & fonts:
#   Everything comes from Stylix (meta/7.stylix.nix). These configs are written
#   by hand as text, so Stylix can't theme them itself — they read
#   config.lib.stylix.colors instead. Change the palette there, rebuild, and
#   i3, polybar and rofi follow.
#
# Key bindings:
#   Super+Q           terminal
#   Super+F           rofi launcher
#   Super+B           browser
#   Super+N           file manager
#   Super+E           close window
#   Super+Alt+L       lock screen
#   Super+V           fullscreen
#   Super+Shift+S     toggle floating/tiling
#   Super+R           resize mode
#   Super+1..9        switch workspace
#   Super+Shift+1..9  move window to workspace
#   Print             screenshot region
#   Super+Print       screenshot full
let
  user = config.profile.username;
  meta = config.meta.defaults;

  # ── Stylix palette + fonts ──────────────────────────────────────────────────
  c      = config.lib.stylix.colors.withHashtag;   # "#rrggbb"
  raw    = config.lib.stylix.colors;               # "rrggbb"
  fonts  = config.stylix.fonts;
  mono   = fonts.monospace.name;
  uiSize = toString fonts.sizes.desktop;

  bg     = c.base00;   # main background
  bgAlt  = c.base01;   # bars / panels
  border = c.base02;   # unfocused borders (slightly lighter than bg)
  dimmed = c.base03;   # muted / inactive
  fg     = c.base05;   # text
  accent = c.base0D;   # focus, selection, active workspace
  urgent = c.base08;   # red

  polybar = pkgs.polybar.override { i3Support = true; pulseSupport = true; };
in
{
  services.xserver.enable                        = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.windowManager.i3 = {
    enable        = true;
    extraPackages = with pkgs; [ i3status i3lock ];
  };

  environment.systemPackages = with pkgs; [
    polybar
    dunst
    rofi
    picom
    feh
    xclip
    xdotool
    vlc
    hardinfo2
    imv
  ];

  home-manager.users.${user} = { lib, ... }: {

    # ── i3 config ─────────────────────────────────────────────────────────────
    xdg.configFile."i3/config".text = ''
      # ── Mod key (Super) ──────────────────────────────────────────────────────
      set $mod Mod4

      # ── Colors (Stylix) ──────────────────────────────────────────────────────
      set $bg      ${bg}
      set $fg      ${fg}
      set $accent  ${accent}
      set $border  ${border}
      set $urgent  ${urgent}

      # ── Font ──────────────────────────────────────────────────────────────
      font pango:${mono} ${uiSize}

      # ── Apps that should always float ─────────────────────────────────────
      for_window [class="Pavucontrol"]          floating enable
      for_window [class="Nm-connection-editor"] floating enable
      for_window [title="File Transfer*"]       floating enable
      for_window [class="Steam" title="Steam"]  floating enable
      for_window [class=".*"] border pixel 3

      # ── Gaps ──────────────────────────────────────────────────────────────
      gaps inner 11
      gaps outer 5
      smart_gaps on

      # ── Borders ───────────────────────────────────────────────────────────
      default_floating_border pixel 3
      default_border           pixel 3
      hide_edge_borders        smart

      # ── Window colors ─────────────────────────────────────────────────────
      # class                 border   backgr.