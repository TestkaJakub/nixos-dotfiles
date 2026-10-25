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
      # class                 border   backgr.  text    indicator child_border
      client.focused          $accent  $bg      $fg     $accent   $accent
      client.unfocused        $border  $bg      $fg     $border   $border
      client.focused_inactive $border  $bg      $fg     $border   $border
      client.urgent           $urgent  $urgent  $fg     $urgent   $urgent

      # ── Autostart ─────────────────────────────────────────────────────────
      exec_always --no-startup-id ${config.scripts.wallpaperInit}/bin/wallpaper-init
      exec_always --no-startup-id ${pkgs.picom}/bin/picom --daemon
      exec_always --no-startup-id bash -c 'pkill polybar; until [ -S /run/user/$(id -u)/i3/ipc-socket.* ] 2>/dev/null; do sleep 0.1; done; ${polybar}/bin/polybar main'
      exec_always --no-startup-id ${pkgs.networkmanagerapplet}/bin/nm-applet
      exec        --no-startup-id ${pkgs.udiskie}/bin/udiskie --tray &
      exec        --no-startup-id ${pkgs.dunst}/bin/dunst &

      # ── Key bindings ──────────────────────────────────────────────────────
      bindsym $mod+q     exec ${meta.terminalPackage}/bin/${meta.terminal}
      bindsym $mod+f     exec ${pkgs.rofi}/bin/rofi -show drun
      bindsym $mod+b     exec ${meta.browserPackage}/bin/${meta.browser}
      bindsym $mod+n       exec ${meta.terminalRun} ${pkgs.yazi}/bin/yazi
      bindsym $mod+Shift+n exec ${meta.fileManagerPackage}/bin/${meta.fileManager}
      bindsym $mod+e     kill
      bindsym $mod+Alt+l exec ${pkgs.i3lock}/bin/i3lock -c ${raw.base00}
      bindsym $mod+v     fullscreen toggle

      bindsym $mod+Shift+s floating toggle

      # Focus
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right
      bindsym $mod+Left  focus left
      bindsym $mod+Down  focus down
      bindsym $mod+Up    focus up
      bindsym $mod+Right focus right

      # Move floating windows
      bindsym $mod+Shift+h move left  20px
      bindsym $mod+Shift+j move down  20px
      bindsym $mod+Shift+k move up    20px
      bindsym $mod+Shift+l move right 20px
      bindsym $mod+Shift+Left  move left  20px
      bindsym $mod+Shift+Down  move down  20px
      bindsym $mod+Shift+Up    move up    20px
      bindsym $mod+Shift+Right move right 20px

      # Workspaces
      bindsym $mod+1 workspace number 1
      bindsym $mod+2 workspace number 2
      bindsym $mod+3 workspace number 3
      bindsym $mod+4 workspace number 4
      bindsym $mod+5 workspace number 5
      bindsym $mod+6 workspace number 6
      bindsym $mod+7 workspace number 7
      bindsym $mod+8 workspace number 8
      bindsym $mod+9 workspace number 9

      bindsym $mod+Shift+1 move container to workspace number 1
      bindsym $mod+Shift+2 move container to workspace number 2
      bindsym $mod+Shift+3 move container to workspace number 3
      bindsym $mod+Shift+4 move container to workspace number 4
      bindsym $mod+Shift+5 move container to workspace number 5
      bindsym $mod+Shift+6 move container to workspace number 6
      bindsym $mod+Shift+7 move container to workspace number 7
      bindsym $mod+Shift+8 move container to workspace number 8
      bindsym $mod+Shift+9 move container to workspace number 9

      # Screenshots
      bindsym Print       exec screenshot-region
      bindsym $mod+Print  exec screenshot-full

      # Volume
      bindsym XF86AudioRaiseVolume exec ${pkgs.pamixer}/bin/pamixer -i 5
      bindsym XF86AudioLowerVolume exec ${pkgs.pamixer}/bin/pamixer -d 5
      bindsym XF86AudioMute        exec ${pkgs.pamixer}/bin/pamixer -t

      # Resize mode
      mode "resize" {
        bindsym h resize shrink width  20px
        bindsym j resize grow   height 20px
        bindsym k resize shrink height 20px
        bindsym l resize grow   width  20px
        bindsym Left  resize shrink width  20px
        bindsym Down  resize grow   height 20px
        bindsym Up    resize shrink height 20px
        bindsym Right resize grow   width  20px
        bindsym Return mode "default"
        bindsym Escape mode "default"
      }
      bindsym $mod+r mode "resize"

      # Reload / restart / exit
      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+r restart
      bindsym $mod+Shift+e exec i3-msg exit

      # Bar managed by polybar — i3bar disabled
    '';

    # ── Polybar ───────────────────────────────────────────────────────────────
    # Colors are baked in from Stylix — no more pywal include file.
    # Icons are Nerd Font glyphs (Stylix monospace = JetBrainsMono Nerd Font).
    xdg.configFile."polybar/config.ini".text = ''
      [colors]
      bg     = ${bgAlt}
      fg     = ${fg}
      accent = ${accent}
      dimmed = ${dimmed}
      urgent = ${urgent}

      [bar/main]
      width            = 100%
      height           = 38
      radius           = 0
      background       = ''${colors.bg}
      foreground       = ''${colors.fg}
      border-size      = 0
      padding-left     = 1
      padding-right    = 1
      module-margin    = 1
      font-0           = ${mono}:size=${uiSize};3
      font-1           = ${mono}:size=${toString (fonts.sizes.desktop + 4)};4
      modules-left     = i3
      modules-center   = date
      modules-right    = volume memory cpu network tray
      cursor-click     = pointer
      override-redirect = false

      [module/i3]
      type                        = internal/i3
      pin-workspaces              = true
      show-urgent                 = true
      strip-wsnumbers             = false
      index-sort                  = true
      label-focused               = %index%
      label-focused-background    = ''${colors.accent}
      label-focused-foreground    = ''${colors.bg}
      label-focused-padding       = 2
      label-unfocused             = %index%
      label-unfocused-foreground  = ''${colors.dimmed}
      label-unfocused-padding     = 2
      label-urgent                = %index%!
      label-urgent-background     = ''${colors.urgent}
      label-urgent-foreground     = ''${colors.bg}
      label-urgent-padding        = 2

      [module/date]
      type          = internal/date
      interval      = 1
      date          = %d-%m-%Y
      time          = %H:%M:%S
      label         = %date%  %time%
      label-foreground = ''${colors.fg}

      [module/volume]
      type                  = internal/pulseaudio
      format-volume         = <ramp-volume> <label-volume>
      label-volume          = %percentage%%
      label-muted           = 󰝟 muted
      label-muted-foreground = ''${colors.dimmed}
      ramp-volume-0         = 󰕿
      ramp-volume-1         = 󰖀
      ramp-volume-2         = 󰕾
      ramp-volume-foreground = ''${colors.accent}
      click-right           = ${pkgs.pavucontrol}/bin/pavucontrol &

      [module/memory]
      type     = internal/memory
      interval = 3
      format-prefix            = "󰍛 "
      format-prefix-foreground = ''${colors.accent}
      label    = %percentage_used%%

      [module/cpu]
      type     = internal/cpu
      interval = 1
      format-prefix            = "󰻠 "
      format-prefix-foreground = ''${colors.accent}
      label    = %percentage%%

      [module/network]
      type                    = internal/network
      interface-type          = wired
      interval                = 3
      format-connected-prefix            = "󰈀 "
      format-connected-prefix-foreground = ''${colors.accent}
      label-connected         = %local_ip%
      label-disconnected      = 󰈂 disconnected
      label-disconnected-foreground = ''${colors.dimmed}

      [module/tray]
      type = internal/tray
    '';

    # ── Rofi ──────────────────────────────────────────────────────────────────
    xdg.configFile."rofi/config.rasi".text = ''
      configuration {
        modi:                "drun,run,window";
        show-icons:          true;
        drun-display-format: "{name}";
        font:                "${mono} ${toString fonts.sizes.popups}";
      }

      * {
        bg:     ${bg};
        bg-alt: ${bgAlt};
        fg:     ${fg};
        dimmed: ${dimmed};
        accent: ${accent};
        urgent: ${urgent};

        background-color: transparent;
        text-color:       @fg;
        border-color:     @accent;
      }

      window {
        background-color: @bg;
        border:           3px;
        border-radius:    5px;
        width:            600px;
        padding:          12px;
      }

      mainbox { spacing: 12px; children: [ inputbar, listview ]; }

      inputbar {
        background-color: @bg-alt;
        border-radius:    5px;
        padding:          10px 12px;
        spacing:          10px;
        children:         [ prompt, entry ];
      }
      prompt { text-color: @accent; }
      entry  { placeholder: "Search…"; placeholder-color: @dimmed; }

      listview {
        lines:     8;
        spacing:   4px;
        scrollbar: false;
        fixed-height: false;
      }

      element {
        padding:       8px 12px;
        spacing:       12px;
        border-radius: 5px;
      }
      element-icon { size: 1.4em; vertical-align: 0.5; }
      element-text { text-color: inherit; vertical-align: 0.5; }

      /* Row states — override every one so no default-theme colors leak */
      element normal.normal,   element alternate.normal   { background-color: transparent; text-color: @fg; }
      element normal.active,   element alternate.active   { background-color: transparent; text-color: @accent; }
      element normal.urgent,   element alternate.urgent   { background-color: transparent; text-color: @urgent; }
      element selected.normal, element selected.active,
      element selected.urgent                             { background-color: @accent; text-color: @bg; }
    '';

        # ── Picom ─────────────────────────────────────────────────────────────────
    # EGL backend: needed for rounded corners + blur; grayscale-toggle uses it too.
    # Fullscreen windows (games, video) are unredirected — no compositor in the way.
    xdg.configFile."picom/picom.conf".text = ''
      # Backend
      backend    = "egl";
      vsync      = true;
      use-damage = true;
      unredir-if-possible = true;

      # Rounded corners
      corner-radius = 8;
      rounded-corners-exclude = [
        "window_type = 'dock'",
        "window_type = 'desktop'",
        "class_g = 'Polybar'",
        "class_g = 'Rofi'",
        "class_g = 'Dunst'",
        "fullscreen"
      ];

      # Blur (behind translucent windows)
      blur-method   = "dual_kawase";
      blur-strength = 5;
      blur-background-exclude = [
        "window_type = 'dock'",
        "window_type = 'desktop'",
        "_GTK_FRAME_EXTENTS@"
      ];

      # Shadows
      shadow          = true;
      shadow-radius   = 12;
      shadow-opacity  = 0.4;
      shadow-offset-x = -8;
      shadow-offset-y = -8;
      shadow-exclude  = [
        "class_g = 'i3-frame'",
        "window_type = 'dock'",
        "_GTK_FRAME_EXTENTS@",
        "fullscreen"
      ];

      # Fading
      fading        = true;
      fade-in-step  = 0.05;
      fade-out-step = 0.05;
      fade-delta    = 5;
    '';
  };
}