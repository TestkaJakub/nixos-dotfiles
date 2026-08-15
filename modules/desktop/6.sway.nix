{ pkgs, config, lib, ... }:

# ── Sway desktop ───────────────────────────────────────────────────────────────
# A parallel session to 6.i3.nix. Keep both files: LightDM shows "Sway" and "i3"
# at the greeter, so you trial Sway and fall back to i3 (or roll back a
# generation) with zero commitment. Bitmask prefix 6 = workstation + desktop,
# matching 6.i3.nix.
#
# WM:          sway (FLOATING by default; tiling summoned on demand)
# Bar:         waybar          (polybar is X11-only → replaced here)
# Launcher:    fuzzel          (rofi is X11; you already had toFuzzel in theme)
# Wallpaper:   sway `output bg` (feh is X11; static for now — see notes below)
# Lock:        swaylock
# Screenshots: grimshot        (scrot is X11; see 6.screenshots.nix note below)
# Clipboard:   wl-clipboard    (xclip is X11)
# Notifs:      dunst           (works on Wayland; shared with i3.nix)
# Portals:     xdg-desktop-portal-wlr (+ gtk) for screen-sharing over PipeWire
# DM:          LightDM (unchanged — an X greeter can launch a Wayland session)
#
# ── The float-first workflow (your (a) + (b) requirement) ─────────────────────
# Every window opens FLOATING. To arrange windows in a tiled layout:
#   1. Focus a window, press $mod+Shift+s   → it drops into the tiling tree.
#   2. Tile more windows the same way; they auto-split (a).
#   3. On the focused tiling container:
#        $mod+w  → tabbed   (b)
#        $mod+s  → stacking (b)
#        $mod+t  → toggle split direction
#   4. $mod+Shift+s again pops a window back out to floating.
# Tabbed/stacked headers render fine even with pixel borders — the tab/stack
# decoration is drawn by the container, not the per-window titlebar.
#
# Key bindings (mirrors your i3 map; layout keys are the additions):
#   Super+Q            terminal
#   Super+F            fuzzel launcher
#   Super+B            browser
#   Super+N            file manager
#   Super+E            close window
#   Super+Alt+L        lock screen (swaylock)
#   Super+V            fullscreen
#   Super+Shift+S      toggle floating/tiling  (tile-on-demand)
#   Super+Space        toggle focus floating<->tiling
#   Super+W / S / T    tabbed / stacking / toggle-split  (on the tiled container)
#   Super+C            center a floating window
#   Super+H/J/K/L      focus
#   Super+Shift+H/J/K/L move
#   Super+1..9         switch workspace
#   Super+Shift+1..9   move window to workspace
#   Super+minus        scratchpad show   /  Super+Shift+minus  move to scratchpad
#   Super+R            resize mode
#   Print              screenshot region (save + clipboard + notify)
#   Super+Print        screenshot current output
#   Super+Shift+C      reload    /  Super+Shift+E  exit (with confirm)
let
  user   = config.profile.username;
  t      = config.theme;
  p      = t.palette;
  meta   = config.meta.defaults;

  bg     = p.secondary;
  fg     = p.primary;
  accent = t.functions.complement p.primary;
  border = p.border;

  bgNoHash  = lib.strings.removePrefix "#" bg;
  wallpaper = meta.wallpaper;
  kbdLayout = config.locale.keyboardLayout;

  # fuzzel wants colours as RRGGBBAA with no leading '#'
  fuzzelC = hex: (lib.strings.removePrefix "#" hex) + "ff";
in
{
  # ── Session ─────────────────────────────────────────────────────────────────
  programs.sway = {
    enable              = true;
    wrapperFeatures.gtk = true;   # GTK apps under the sway wrapper
    # XWayland ships with sway by default; X-only apps (electron, bambu via xcb,
    # steam, etc.) keep working.
  };

  # LightDM is an X greeter but can launch the Sway Wayland session. Declared
  # here too (identical to i3.nix, so it merges) so this module is self-contained
  # if you ever delete 6.i3.nix.
  services.xserver.enable                        = true;
  services.xserver.displayManager.lightdm.enable = true;

  # swaylock needs a PAM entry or it can never authenticate the unlock.
  security.pam.services.swaylock = {};

  # Screen-sharing / screenshot portals over PipeWire (you already run PipeWire).
  xdg.portal = {
    enable       = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.sway.default = [ "hyprland" "gtk" ];
  };

  environment.systemPackages = with pkgs; [
    waybar
    fuzzel
    swaylock
    swayidle
    grim
    slurp
    sway-contrib.grimshot
    wl-clipboard
    swaybg
    dunst          # also in i3.nix; harmless duplicate, keeps this module standalone
  ];

  home-manager.users.${user} = { lib, ... }: {

    # ── Sway config ───────────────────────────────────────────────────────────
    xdg.configFile."sway/config".text = ''
      # ── Mod key (Super) ──────────────────────────────────────────────────────
      set $mod Mod4

      # ── Colours from theme.palette (Nix-generated, static) ───────────────────
      set $bg      ${bg}
      set $fg      ${fg}
      set $accent  ${accent}
      set $border  ${border}

      # ── Font (also used for tab/stack headers) ───────────────────────────────
      font pango:JetBrains Mono 14
      title_align center

      # ── FLOAT BY DEFAULT ─────────────────────────────────────────────────────
      # app_id matches native Wayland windows; class matches XWayland windows.
      # (A rare window with neither an app_id nor a class won't match — add a
      #  title rule if you ever hit one.)
      for_window [app_id=".*"] floating enable
      for_window [class=".*"]  floating enable

      # Drag to move with $mod; $mod+right-drag to resize.
      floating_modifier $mod normal

      # ── Gaps / borders (your i3 look) ────────────────────────────────────────
      gaps inner 11
      gaps outer 5
      smart_gaps on

      default_floating_border pixel 3
      default_border          pixel 3
      hide_edge_borders       smart

      # ── Window colours ───────────────────────────────────────────────────────
      # class                 border   backgr.  text   indicator child_border
      client.focused          $accent  $bg      $fg    $accent   $accent
      client.unfocused        $border  $bg      $fg    $border   $border
      client.focused_inactive $border  $bg      $fg    $border   $border
      client.urgent           #e06c75  #e06c75  $fg    #e06c75   #e06c75

      # ── Input ────────────────────────────────────────────────────────────────
      # NOTE: services.libinput in system/mouse.nix only configures Xorg. Sway
      # drives libinput itself via wlroots, so your flat 1:1 Model O- tuning is
      # re-declared here or it won't apply under Wayland.
      input "type:keyboard" {
        xkb_layout ${kbdLayout}
      }
      input "type:pointer" {
        accel_profile flat
        pointer_accel 0
      }

      seat seat0 xcursor_theme Adwaita 24

      # ── Output: wallpaper + scaling ──────────────────────────────────────────
      # Your X setup runs Xft.dpi 131 (~1.36 scale). 1.333 is a close, cleaner
      # fractional match; run `swaymsg -t get_outputs` to get the real output
      # name and tune per-monitor. If XWayland apps look soft at fractional
      # scale, use integer `scale 1` and bump font sizes instead.
      output * {
        bg ${wallpaper} fill
      }

      # ── Autostart ────────────────────────────────────────────────────────────
      # Export the Wayland env into the user systemd + dbus activation env so
      # portals (screen-share) and any WantedBy=graphical-session.target units
      # can see WAYLAND_DISPLAY.
      exec_always systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      exec_always ${pkgs.waybar}/bin/waybar
      exec        ${pkgs.dunst}/bin/dunst
      exec        ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
      exec        ${pkgs.udiskie}/bin/udiskie --tray
      # EasyEffects is a systemd user service; exec it too in case the session
      # target isn't wired under Sway (dbus makes the 2nd instance a no-op).
      exec        ${pkgs.easyeffects}/bin/easyeffects --gapplication-service

      # ── Apps ─────────────────────────────────────────────────────────────────
      bindsym $mod+q     exec ${meta.terminalPackage}/bin/${meta.terminal}
      bindsym $mod+f     exec ${pkgs.fuzzel}/bin/fuzzel
      bindsym $mod+b     exec ${meta.browserPackage}/bin/${meta.browser}
      bindsym $mod+n     exec ${meta.fileManagerPackage}/bin/${meta.fileManager}
      bindsym $mod+e     kill
      bindsym $mod+Alt+l exec ${pkgs.swaylock}/bin/swaylock -f -c ${bgNoHash}
      bindsym $mod+v     fullscreen toggle

      # ── Float / tile on demand ───────────────────────────────────────────────
      bindsym $mod+Shift+s floating toggle
      bindsym $mod+space   focus mode_toggle
      bindsym $mod+c       move position center

      # ── Tiling container layouts — your (a) + (b) ────────────────────────────
      bindsym $mod+w layout tabbed
      bindsym $mod+s layout stacking
      bindsym $mod+t layout toggle split

      # ── Focus ────────────────────────────────────────────────────────────────
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right
      bindsym $mod+Left  focus left
      bindsym $mod+Down  focus down
      bindsym $mod+Up    focus up
      bindsym $mod+Right focus right

      # ── Move (px for floating, tree-move for tiled) ──────────────────────────
      bindsym $mod+Shift+h move left  20px
      bindsym $mod+Shift+j move down  20px
      bindsym $mod+Shift+k move up    20px
      bindsym $mod+Shift+l move right 20px
      bindsym $mod+Shift+Left  move left  20px
      bindsym $mod+Shift+Down  move down  20px
      bindsym $mod+Shift+Up    move up    20px
      bindsym $mod+Shift+Right move right 20px

      # ── Scratchpad ───────────────────────────────────────────────────────────
      bindsym $mod+Shift+minus move scratchpad
      bindsym $mod+minus       scratchpad show

      # ── Workspaces ───────────────────────────────────────────────────────────
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

      # ── Screenshots (grimshot: save + clipboard + notify) ────────────────────
      bindsym Print      exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy area
      bindsym $mod+Print exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy output

      # ── Volume ───────────────────────────────────────────────────────────────
      bindsym XF86AudioRaiseVolume exec ${pkgs.pamixer}/bin/pamixer -i 5
      bindsym XF86AudioLowerVolume exec ${pkgs.pamixer}/bin/pamixer -d 5
      bindsym XF86AudioMute        exec ${pkgs.pamixer}/bin/pamixer -t

      # ── Resize mode ──────────────────────────────────────────────────────────
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

      # ── Reload / exit ────────────────────────────────────────────────────────
      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+e exec ${pkgs.sway}/bin/swaynag -t warning \
        -m 'Exit sway?' -B 'Yes, exit' 'swaymsg exit'

      # Bar is waybar, launched above — sway's built-in bar stays disabled.
    '';

    # ── Waybar ──────────────────────────────────────────────────────────────────
    # Launched from sway autostart (systemd integration off) so it starts the
    # same way your polybar does under i3.
    programs.waybar = {
      enable         = true;
      systemd.enable = false;
      settings.mainBar = {
        layer    = "top";
        position = "top";
        height   = 38;
        modules-left   = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "clock" ];
        modules-right  = [ "pulseaudio" "memory" "cpu" "network" "tray" ];

        "sway/workspaces" = {
          disable-scroll = false;
          format         = "{name}";
        };
        "clock" = {
          interval = 1;
          format   = "{:%d-%m-%Y  %H:%M:%S}";
        };
        "pulseaudio" = {
          format         = "{icon} {volume}%";
          format-muted   = "muted";
          format-icons   = { default = [ "" "" "" ]; };
          on-click       = "${pkgs.pavucontrol}/bin/pavucontrol";
        };
        "memory" = { interval = 3; format = " {percentage}%"; };
        "cpu"    = { interval = 1; format = " {usage}%"; };
        "network" = {
          interval           = 3;
          format-ethernet    = " {ipaddr}";
          format-disconnected = " disconnected";
          tooltip-format     = "{ifname}: {ipaddr}";
        };
        "tray" = { spacing = 8; };
      };

      style = ''
        * {
          font-family: "JetBrains Mono";
          font-size: 14px;
          min-height: 0;
        }
        window#waybar {
          background-color: ${bg};
          color: ${fg};
        }
        #workspaces button {
          padding: 0 8px;
          color: ${fg};
          background: transparent;
        }
        #workspaces button.focused {
          background-color: ${accent};
          color: ${bg};
        }
        #workspaces button.urgent {
          background-color: #e06c75;
          color: ${bg};
        }
        #clock, #pulseaudio, #memory, #cpu, #network, #tray {
          padding: 0 10px;
          color: ${fg};
        }
      '';
    };

    # ── Fuzzel ──────────────────────────────────────────────────────────────────
    xdg.configFile."fuzzel/fuzzel.ini".text = ''
      [main]
      font=JetBrains Mono:size=15
      width=30
      lines=12

      [colors]
      background=${fuzzelC bg}
      text=${fuzzelC fg}
      selection=${fuzzelC accent}
      selection-text=${fuzzelC bg}
      border=${fuzzelC accent}

      [border]
      width=3
      radius=5
    '';
  };
}