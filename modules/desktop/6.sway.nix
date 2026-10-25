{ pkgs, config, lib, ... }:

# ── Sway desktop ───────────────────────────────────────────────────────────────
# A parallel session to 6.i3.nix. Keep both files: LightDM shows "Sway" and "i3"
# at the greeter, so you trial Sway and fall back to i3 (or roll back a
# generation) with zero commitment. Bitmask prefix 6 = workstation + desktop,
# matching 6.i3.nix.
#
# WM:          sway (FLOATING by default; tiling summoned on demand)
# Bar:         waybar
# Launcher:    fuzzel
# Wallpaper:   sway `output bg`
# Lock:        swaylock
# Screenshots: grimshot
# Clipboard:   wl-clipboard
# Notifs:      dunst (shared with i3.nix)
# Portals:     xdg-desktop-portal-hyprland (+ gtk) for screen-sharing over PipeWire
# DM:          LightDM (an X greeter can launch a Wayland session)
#
# Colors & fonts:
#   Everything comes from Stylix (meta/7.stylix.nix) via config.lib.stylix.colors.
#   Stylix's own waybar target is disabled below — this module owns the bar CSS
#   so the two don't stack on top of each other.
#
# ── The float-first workflow ──────────────────────────────────────────────────
# Every window opens FLOATING. To arrange windows in a tiled layout:
#   1. Focus a window, press $mod+Shift+s   → it drops into the tiling tree.
#   2. Tile more windows the same way; they auto-split.
#   3. On the focused tiling container:
#        $mod+w  → tabbed
#        $mod+s  → stacking
#        $mod+t  → toggle split direction
#   4. $mod+Shift+s again pops a window back out to floating.
#
# Key bindings:
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
  user = config.profile.username;
  meta = config.meta.defaults;

  # ── Stylix palette + fonts ──────────────────────────────────────────────────
  c      = config.lib.stylix.colors.withHashtag;   # "#rrggbb"
  raw    = config.lib.stylix.colors;               # "rrggbb"
  fonts  = config.stylix.fonts;
  cursor = config.stylix.cursor;
  mono   = fonts.monospace.name;
  uiSize = toString fonts.sizes.desktop;

  bg     = c.base00;   # main background
  bgAlt  = c.base01;   # bars / panels
  border = c.base02;   # unfocused borders
  dimmed = c.base03;   # muted / inactive
  fg     = c.base05;   # text
  accent = c.base0D;   # focus, selection, active workspace
  urgent = c.base08;   # red

  wallpaper = meta.wallpaper;
  kbdLayout = config.locale.keyboardLayout;

  # fuzzel wants colours as RRGGBBAA with no leading '#'
  fuzzelC = hex: (lib.strings.removePrefix "#" hex) + "ff";
in
{
  # ── Session ─────────────────────────────────────────────────────────────────
  programs.sway = {
    enable              = true;
    wrapperFeatures.gtk = true;
  };

  services.xserver.enable                        = true;
  services.xserver.displayManager.lightdm.enable = true;

  # swaylock needs a PAM entry or it can never authenticate the unlock.
  security.pam.services.swaylock = {};

  xdg.portal = {
    enable       = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.sway.default = lib.mkForce [ "hyprland" "gtk" ];
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
    dunst
  ];

  home-manager.users.${user} = { lib, ... }: {

    # This module writes its own waybar CSS from the Stylix palette.
    stylix.targets.waybar.enable = false;

    # ── Sway config ───────────────────────────────────────────────────────────
    xdg.configFile."sway/config".text = ''
      # ── Mod key (Super) ──────────────────────────────────────────────────────
      set $mod Mod4

      # ── Colours (Stylix) ─────────────────────────────────────────────────────
      set $bg      ${bg}
      set $fg      ${fg}
      set $accent  ${accent}
      set $border  ${border}
      set $urgent  ${urgent}

      # ── Font (also used for tab/stack headers) ───────────────────────────────
      font pango:${mono} ${uiSize}
      title_align center

      # ── FLOAT BY DEFAULT ─────────────────────────────────────────────────────
      for_window [app_id=".*"] floating enable
      for_window [class=".*"]  floating enable

      # Drag to move with $mod; $mod+right-drag to resize.
      floating_modifier $mod normal

      # ── Gaps / borders ───────────────────────────────────────────────────────
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
      client.urgent           $urgent  $urgent  $fg    $urgent   $urgent

      # ── Input ────────────────────────────────────────────────────────────────
      input "type:keyboard" {
        xkb_layout ${kbdLayout}
      }
      input "type:pointer" {
        accel_profile flat
        pointer_accel 0
      }

      # Cursor follows Stylix so sway and apps agree on theme + size
      seat seat0 xcursor_theme ${cursor.name} ${toString cursor.size}

      # ── Output: wallpaper ────────────────────────────────────────────────────
      output * {
        bg ${wallpaper} fill ${bg}
      }

      # ── Autostart ────────────────────────────────────────────────────────────
      exec_always systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK
      exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      # pkill first so a reload ($mod+Shift+c) doesn't stack a second bar
      exec_always sh -c 'pkill -x waybar; exec ${pkgs.waybar}/bin/waybar'
      exec        ${pkgs.dunst}/bin/dunst
      exec        ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
      exec        ${pkgs.udiskie}/bin/udiskie --tray
      exec        ${pkgs.easyeffects}/bin/easyeffects --gapplication-service

      # ── Apps ─────────────────────────────────────────────────────────────────
      bindsym $mod+q     exec ${meta.terminalPackage}/bin/${meta.terminal}
      bindsym $mod+f     exec ${pkgs.fuzzel}/bin/fuzzel
      bindsym $mod+b     exec ${meta.browserPackage}/bin/${meta.browser}
      bindsym $mod+n       exec ${meta.terminalRun} ${pkgs.yazi}/bin/yazi
      bindsym $mod+Shift+n exec ${meta.fileManagerPackage}/bin/${meta.fileManager}
      bindsym $mod+e     kill
      bindsym $mod+Alt+l exec ${pkgs.swaylock}/bin/swaylock -f -c ${raw.base00}
      bindsym $mod+v     fullscreen toggle

      # ── Float / tile on demand ───────────────────────────────────────────────
      bindsym $mod+Shift+s floating toggle
      bindsym $mod+space   focus mode_toggle
      bindsym $mod+c       move position center

      # ── Tiling container layouts ─────────────────────────────────────────────
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

      # ── Move ─────────────────────────────────────────────────────────────────
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
    '';

    # ── Waybar ──────────────────────────────────────────────────────────────────
    programs.waybar = {
      enable         = true;
      systemd.enable = false;
      settings.mainBar = {
        layer    = "top";
        position = "top";
        height   = 38;
        modules-left   = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "clock" ];
        modules-right  = [ "custom/bing" "pulseaudio" "memory" "cpu" "network" "tray" ];

        "sway/workspaces" = {
          disable-scroll = false;
          format         = "{name}";
        };
        "custom/bing" = {
          exec     = "cat ~/.cache/bing-wallpaper/current.txt";
          interval = 3600;
          on-click = ''xdg-open "$(${pkgs.jq}/bin/jq -r .link ~/.cache/bing-wallpaper/current.json)"'';
        };
        "clock" = {
          interval = 1;
          format   = "{:%d-%m-%Y  %H:%M:%S}";
        };
        "pulseaudio" = {
          format       = "{icon} {volume}%";
          format-muted = "󰝟 muted";
          format-icons = { default = [ "󰕿" "󰖀" "󰕾" ]; };
          on-click     = "${pkgs.pavucontrol}/bin/pavucontrol";
        };
        "memory"  = { interval = 3; format = "󰍛 {percentage}%"; };
        "cpu"     = { interval = 1; format = "󰻠 {usage}%"; };
        "network" = {
          interval            = 3;
          format-ethernet     = "󰈀 {ipaddr}";
          format-disconnected = "󰈂 disconnected";
          tooltip-format      = "{ifname}: {ipaddr}";
        };
        "tray" = { spacing = 8; };
      };

      style = ''
        * {
          font-family: "${mono}";
          font-size: ${uiSize}pt;
          min-height: 0;
        }
        window#waybar {
          background-color: ${bgAlt};
          color: ${fg};
        }
        tooltip {
          background-color: ${bg};
          border: 2px solid ${accent};
          border-radius: 5px;
        }
        #workspaces button {
          padding: 0 8px;
          color: ${dimmed};
          background: transparent;
          border-radius: 0;
        }
        #workspaces button.focused {
          background-color: ${accent};
          color: ${bg};
        }
        #workspaces button.urgent {
          background-color: ${urgent};
          color: ${bg};
        }
        #mode {
          background-color: ${urgent};
          color: ${bg};
          padding: 0 10px;
        }
        #clock, #pulseaudio, #memory, #cpu, #network, #tray, #custom-bing {
          padding: 0 10px;
          color: ${fg};
        }
        #custom-bing {
          color: ${dimmed};
        }
        #pulseaudio.muted, #network.disconnected {
          color: ${dimmed};
        }
      '';
    };

    # ── Fuzzel ──────────────────────────────────────────────────────────────────
    xdg.configFile."fuzzel/fuzzel.ini".text = ''
      [main]
      font=${mono}:size=${toString fonts.sizes.popups}
      width=30
      lines=12

      [colors]
      background=${fuzzelC bg}
      text=${fuzzelC fg}
      prompt=${fuzzelC accent}
      placeholder=${fuzzelC dimmed}
      input=${fuzzelC fg}
      match=${fuzzelC accent}
      selection=${fuzzelC accent}
      selection-text=${fuzzelC bg}
      selection-match=${fuzzelC bg}
      border=${fuzzelC accent}

      [border]
      width=3
      radius=5
    '';
  };
}