{ pkgs, config, lib, ... }:

# ── i3 desktop ─────────────────────────────────────────────────────────────────
# WM:          i3 (floating by default, Super+Shift+Space to toggle tiling)
# Bar:         polybar
# Launcher:    rofi
# Compositor:  picom
# Wallpaper:   feh
# DM:          LightDM (unchanged)
#
# Key bindings:
#   Super+Enter       terminal
#   Super+D           rofi launcher
#   Super+B           browser
#   Super+E           file manager
#   Super+Shift+Q     close window
#   Super+Shift+Space toggle floating/tiling
#   Super+F           fullscreen
#   Super+1..9        switch workspace
#   Super+Shift+1..9  move window to workspace
#   Print             screenshot region
#   Super+Print       screenshot full
#   Super+L           lock screen
let
  user    = config.profile.username;
  t       = config.theme;
  p       = t.palette;
  meta    = config.meta.defaults;

  bg      = p.secondary;   # #1f1f1f
  fg      = p.primary;     # #b1b1b1
  accent  = t.functions.complement p.primary;
  border  = p.border;

  wallpaper = meta.wallpaper;
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
    rofi
    picom
    feh
    xclip
    xdotool      # used by some polybar modules
    vlc
    hardinfo2
    kdiff3
    lxqt.lximage-qt   # image viewer — still useful standalone
    lxqt.lxqt-archiver
  ];

  home-manager.users.${user} = { lib, ... }: {

    # ── i3 config ─────────────────────────────────────────────────────────────
    xdg.configFile."i3/config".text = ''
      # ── Mod key (Super) ──────────────────────────────────────────────────────
      set $mod Mod4

      # ── Colors from theme.palette ─────────────────────────────────────────
      set $bg      ${bg}
      set $fg      ${fg}
      set $accent  ${accent}
      set $border  ${border}

      # ── Font ──────────────────────────────────────────────────────────────
      font pango:JetBrains Mono 10

      # ── Floating by default ───────────────────────────────────────────────
      # All windows float unless explicitly tiled
      for_window [class=".*"] floating enable

      # ── Apps that should always float ─────────────────────────────────────
      for_window [class="Pavucontrol"]         floating enable
      for_window [class="Nm-connection-editor"] floating enable
      for_window [title="File Transfer*"]      floating enable
      for_window [class="Steam" title="Steam"] floating enable

      # ── Gaps ─────────────────────────────────────────────────────────────
      gaps inner 8
      gaps outer 4
      smart_gaps on

      # ── Borders ──────────────────────────────────────────────────────────
      default_floating_border pixel 2
      default_border           pixel 2
      hide_edge_borders        smart

      # ── Window colors ─────────────────────────────────────────────────────
      # class                 border   backgr.  text    indicator child_border
      client.focused          $accent  $bg      $fg     $accent   $accent
      client.unfocused        $border  $bg      $fg     $border   $border
      client.focused_inactive $border  $bg      $fg     $border   $border
      client.urgent           #e06c75  #e06c75  $fg     #e06c75   #e06c75

      # ── Autostart ────────────────────────────────────────────────────────
      exec_always --no-startup-id ${pkgs.feh}/bin/feh --bg-scale ${wallpaper}
      exec_always --no-startup-id ${pkgs.picom}/bin/picom --daemon
      exec_always --no-startup-id ${polybar}/bin/polybar main &
      exec        --no-startup-id ${pkgs.udiskie}/bin/udiskie --tray &

      # ── Key bindings ─────────────────────────────────────────────────────
      bindsym $mod+q      exec ${meta.terminalPackage}/bin/${meta.terminal}
      bindsym $mod+f           exec ${pkgs.rofi}/bin/rofi -show drun
      bindsym $mod+b           exec ${meta.browserPackage}/bin/${meta.browser}
      bindsym $mod+n           exec ${meta.fileManagerPackage}/bin/${meta.fileManager}
      bindsym $mod+e     kill
      bindsym $mod+Alt+l       exec ${pkgs.i3lock}/bin/i3lock -c ${lib.strings.removePrefix "#" bg}
      bindsym $mod+v           fullscreen toggle

      # Toggle floating/tiling
      bindsym $mod+Shift+s   floating toggle

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
      # bar { ... }
    '';

    # ── Polybar ───────────────────────────────────────────────────────────────
    xdg.configFile."polybar/config.ini".text = ''
      [colors]
      bg      = ${bg}
      fg      = ${fg}
      accent  = ${accent}
      dimmed  = ${t.functions.darken bg 0.05}
      urgent  = #e06c75

      [bar/main]
      width            = 100%
      height           = 28
      radius           = 0
      background       = ''${colors.bg}
      foreground       = ''${colors.fg}
      border-size      = 0
      padding-left     = 1
      padding-right    = 1
      module-margin    = 1
      font-0           = JetBrains Mono:size=10;2
      font-1           = JetBrains Mono:size=14;3
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
      label-focused-foreground    = ${bg}
      label-focused-padding       = 2
      label-unfocused             = %index%
      label-unfocused-padding     = 2
      label-urgent                = %index%!
      label-urgent-background     = ''${colors.urgent}
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
      label-muted           = muted
      label-muted-foreground = ''${colors.dimmed}
      ramp-volume-0         = 
      ramp-volume-1         = 
      ramp-volume-2         = 
      click-right           = ${pkgs.pavucontrol}/bin/pavucontrol &

      [module/memory]
      type     = internal/memory
      interval = 3
      label    =  %percentage_used%%

      [module/cpu]
      type     = internal/cpu
      interval = 1
      label    =  %percentage%%

      [module/network]
      type                    = internal/network
      interface-type          = wired
      interval                = 3
      label-connected         =  %local_ip%
      label-disconnected      =  disconnected
      label-disconnected-foreground = ''${colors.dimmed}

      [module/tray]
      type = internal/tray
    '';

    # ── Rofi ──────────────────────────────────────────────────────────────────
    xdg.configFile."rofi/config.rasi".text = ''
      configuration {
        modi:           "drun,run,window";
        show-icons:     true;
        drun-display-format: "{name}";
        font:           "JetBrains Mono 11";
      }

      * {
        bg:     ${bg};
        fg:     ${fg};
        accent: ${accent};

        background-color: transparent;
        text-color:       @fg;
      }

      window {
        background-color: @bg;
        border:           2px;
        border-color:     @accent;
        border-radius:    4px;
        width:            480px;
      }

      mainbox       { background-color: @bg; }
      inputbar      { background-color: @bg; padding: 8px; }
      entry         { background-color: @bg; }
      prompt        { text-color: @accent; }

      listview      { background-color: @bg; padding: 4px 0; }
      element       { padding: 6px 8px; }
      element selected {
        background-color: @accent;
        text-color:       ${bg};
      }
    '';

    # ── Picom ─────────────────────────────────────────────────────────────────
    xdg.configFile."picom/picom.conf".text = ''
      # Shadows
      shadow          = true;
      shadow-radius   = 8;
      shadow-opacity  = 0.4;
      shadow-offset-x = -4;
      shadow-offset-y = -4;
      shadow-exclude  = [ "class_g = 'i3-frame'" ];

      # Transparency
      inactive-opacity         = 0.92;
      active-opacity           = 1.0;
      frame-opacity            = 1.0;
      inactive-opacity-override = false;

      opacity-rule = [
        "85:class_g = 'Alacritty'",
        "85:class_g = 'org.wezfurlong.wezterm'",
        "90:class_g = 'VSCodium'",
        "90:class_g = 'firefox'"
      ];

      # Fading
      fading        = true;
      fade-in-step  = 0.05;
      fade-out-step = 0.05;
      fade-delta    = 5;

      # Backend
      backend    = "xrender";
      vsync      = false;
    '';
  };
}