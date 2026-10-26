{ pkgs, config, lib, ... }:

# ── Hyprland desktop ───────────────────────────────────────────────────────────
# A third session next to 6.i3.nix and 6.sway.nix. LightDM lists all three, so
# you can trial Hyprland and fall back to sway/i3 (or roll back a generation)
# at any time. Prefix 6 = workstation + desktop, same as its siblings.
#
# Reused from the sway stack: waybar, fuzzel (its config lives in 6.sway.nix),
# swaylock, swaybg, dunst, udiskie, wl-clipboard.
# New here: grimblast (screenshots), Hyprland's own portal (via programs.hyprland).
#
# Config language: Lua (Hyprland ≥ 0.55; hyprlang is deprecated and gone in 0.56).
#   Written by hand in `extraConfig` below rather than through home-manager's
#   `settings` → Lua generator, which turns every bind into an _args/mkLuaInline
#   block. Other modules can append Lua with:
#     wayland.windowManager.hyprland.extraConfig = lib.mkAfter '' ... '';
#   Errors: `hyprctl configerrors`. Type errors don't stop the rest of the file.
#
# Colours:
#   Read from config.lib.stylix.colors, like 6.sway.nix / 6.i3.nix. Stylix's own
#   hyprland target is off — it still writes hyprlang-shaped settings.
#   Wallpaper is swaybg (same as sway) so bing-wallpaper drives both sessions.
#
# Autostart:
#   home-manager's systemd integration starts hyprland-session.target, which
#   binds graphical-session.target — so easyeffects and udiskie (HM user
#   services) start on their own here. Dunst is D-Bus activated.
#
# ── Float-first, like 6.sway.nix ──────────────────────────────────────────────
# Every window opens FLOATING. $mod+Shift+S drops it into the dwindle tree.
#   $mod+W      toggle group  (≈ sway tabbed)     $mod+Tab  next tab in group
#   $mod+T      toggle split direction of the focused tiled window
#
# Key bindings (same as sway where an equivalent exists):
#   Super+Q / F / B         terminal / fuzzel / browser
#   Super+N / Shift+N       yazi / nemo
#   Super+E                 close window
#   Super+Alt+L             lock (swaylock)
#   Super+V                 fullscreen
#   Super+Shift+S           toggle floating/tiling
#   Super+C                 center floating window
#   Super+H/J/K/L           focus           Super+Shift+H/J/K/L  move 20px
#   Super+1..9              workspace       Super+Shift+1..9     move to workspace
#   Super+minus             scratchpad      Super+Shift+minus    send to scratchpad
#   Super+R                 resize mode (h/j/k/l, Esc/Enter to leave)
#   Super+drag / right-drag move / resize
#   Print / Super+Print     screenshot area / output (save + clipboard + notify)
#   Super+Shift+C           reload          Super+Shift+E        exit (confirm)
let
  user = config.profile.username;
  meta = config.meta.defaults;

  c      = config.lib.stylix.colors.withHashtag;
  raw    = config.lib.stylix.colors;
  cursor = config.stylix.cursor;

  bg     = c.base00;
  accent = c.base0D;
  urgent = c.base08;

  wallpaper = meta.wallpaper;
  kbdLayout = config.locale.keyboardLayout;

  grimblast = "${pkgs.grimblast}/bin/grimblast";
  pamixer   = "${pkgs.pamixer}/bin/pamixer";

  # Keeps nested quoting out of the Lua bind
  exitPrompt = pkgs.writeShellScript "hypr-exit-prompt" ''
    ${pkgs.sway}/bin/swaynag -t warning -m 'Exit Hyprland?' \
      -B 'Yes, exit' "hyprctl dispatch 'hl.dsp.exit()'"
  '';
in
{
  # ── Session ─────────────────────────────────────────────────────────────────
  # Adds Hyprland to LightDM, its portal, polkit, xwayland.
  programs.hyprland.enable = true;

  # Duplicates of what 6.sway.nix declares, so this file still works on its own
  # once sway is gone. Identical definitions merge harmlessly.
  security.pam.services.swaylock = {};

  environment.systemPackages = with pkgs; [
    waybar
    fuzzel
    swaylock
    swaybg
    wl-clipboard
    grimblast
    hyprpicker
  ];

  home-manager.users.${user} = { lib, ... }: {

    # Colours are applied by hand below; wallpaper is swaybg.
    stylix.targets.hyprland.enable           = false;
    stylix.targets.hyprland.hyprpaper.enable = false;

    wayland.windowManager.hyprland = {
      enable        = true;
      package       = null;   # use programs.hyprland's package + portal
      portalPackage = null;
      configType    = "lua";

      # Push the whole session env into systemd so user services
      # (easyeffects, udiskie, bing-wallpaper timer) see WAYLAND_DISPLAY etc.
      systemd.variables = [ "--all" ];

      extraConfig = ''
        -- ── Look & feel ───────────────────────────────────────────────────────
        hl.config({
          input = {
            kb_layout     = "${kbdLayout}",
            follow_mouse  = 1,
            accel_profile = "flat",     -- matches 6.mouse.nix / sway
            sensitivity   = 0,
          },

          general = {
            gaps_in     = 5,
            gaps_out    = 5,
            border_size = 3,
            layout      = "dwindle",
            col = {
              active_border   = "rgb(${raw.base0D})",
              inactive_border = "rgb(${raw.base02})",
            },
          },

          decoration = {
            rounding = 8,               -- same as picom on i3
            blur = {
              enabled = true,
              size    = 6,
              passes  = 2,
            },
          },

          dwindle = {
            preserve_split = true,      -- required for layout togglesplit
          },

          misc = {
            disable_hyprland_logo   = true,
            force_default_wallpaper = 0,
          },
        })

        -- ── Float by default ──────────────────────────────────────────────────
        hl.window_rule({ match = { class = ".*" }, float = true })

        -- ── Autostart ─────────────────────────────────────────────────────────
        hl.on("hyprland.start", function()
          hl.exec_cmd("${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill")
          hl.exec_cmd("${pkgs.waybar}/bin/waybar")
          hl.exec_cmd("${pkgs.networkmanagerapplet}/bin/nm-applet --indicator")
          hl.exec_cmd("hyprctl setcursor ${cursor.name} ${toString cursor.size}")
        end)

        -- ── Binds ─────────────────────────────────────────────────────────────
        local mod      = "SUPER + "
        local modShift = "SUPER + SHIFT + "

        -- Apps
        hl.bind(mod .. "Q",        hl.dsp.exec_cmd("${meta.terminalPackage}/bin/${meta.terminal}"))
        hl.bind(mod .. "F",        hl.dsp.exec_cmd("${pkgs.fuzzel}/bin/fuzzel"))
        hl.bind(mod .. "B",        hl.dsp.exec_cmd("${meta.browserPackage}/bin/${meta.browser}"))
        hl.bind(mod .. "N",        hl.dsp.exec_cmd("${meta.terminalRun} ${pkgs.yazi}/bin/yazi"))
        hl.bind(modShift .. "N",   hl.dsp.exec_cmd("${meta.fileManagerPackage}/bin/${meta.fileManager}"))
        hl.bind(mod .. "E",        hl.dsp.window.close())
        hl.bind(mod .. "ALT + L",  hl.dsp.exec_cmd("${pkgs.swaylock}/bin/swaylock -f -c ${raw.base00}"))
        hl.bind(mod .. "V",        hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

        -- Float / tile on demand
        hl.bind(modShift .. "S",   hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mod .. "C",        hl.dsp.window.center())

        -- Tiling: groups ≈ tabbed, split toggle
        hl.bind(mod .. "W",        hl.dsp.group.toggle())
        hl.bind(mod .. "Tab",      hl.dsp.group.next())
        hl.bind(mod .. "T",        hl.dsp.layout("togglesplit"))

        -- Focus (hjkl + arrows)
        local dirs = {
          { "H", "left" },  { "J", "down" },  { "K", "up" },    { "L", "right" },
          { "left", "left" }, { "down", "down" }, { "up", "up" }, { "right", "right" },
        }
        for _, d in ipairs(dirs) do
          hl.bind(mod .. d[1], hl.dsp.focus({ direction = d[2] }))
        end

        -- Move floating windows 20px (sway's `move left 20px`)
        local steps = {
          { "H", -20, 0 }, { "J", 0, 20 }, { "K", 0, -20 }, { "L", 20, 0 },
          { "left", -20, 0 }, { "down", 0, 20 }, { "up", 0, -20 }, { "right", 20, 0 },
        }
        for _, s in ipairs(steps) do
          hl.bind(modShift .. s[1],
            hl.dsp.window.move({ x = s[2], y = s[3], relative = true }),
            { repeating = true })
        end

        -- Workspaces
        for i = 1, 9 do
          hl.bind(mod .. i,      hl.dsp.focus({ workspace = i }))
          hl.bind(modShift .. i, hl.dsp.window.move({ workspace = i }))
        end

        -- Scratchpad
        hl.bind(mod .. "minus",      hl.dsp.workspace.toggle_special("scratch"))
        hl.bind(modShift .. "minus", hl.dsp.window.move({ workspace = "special:scratch" }))

        -- Screenshots (save to XDG pictures + clipboard + notify)
        hl.bind("Print",        hl.dsp.exec_cmd("${grimblast} --notify copysave area"))
        hl.bind(mod .. "Print", hl.dsp.exec_cmd("${grimblast} --notify copysave output"))

        -- Volume: repeat on hold, work on the lock screen
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("${pamixer} -i 5"), { locked = true, repeating = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("${pamixer} -d 5"), { locked = true, repeating = true })
        hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("${pamixer} -t"),   { locked = true })

        -- Mouse: drag to move, right-drag to resize
        hl.bind(mod .. "mouse:272", hl.dsp.window.drag(),   { mouse = true })
        hl.bind(mod .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

        -- Reload / exit
        hl.bind(modShift .. "C", hl.dsp.exec_cmd("hyprctl reload"))
        hl.bind(modShift .. "E", hl.dsp.exec_cmd("${exitPrompt}"))

        -- ── Resize mode ───────────────────────────────────────────────────────
        hl.define_submap("resize", function()
          local r = {
            { "h", -20, 0 }, { "j", 0, 20 }, { "k", 0, -20 }, { "l", 20, 0 },
            { "left", -20, 0 }, { "down", 0, 20 }, { "up", 0, -20 }, { "right", 20, 0 },
          }
          for _, s in ipairs(r) do
            hl.bind(s[1], hl.dsp.window.resize({ x = s[2], y = s[3], relative = true }),
              { repeating = true })
          end
          hl.bind("Return", hl.dsp.submap("reset"))
          hl.bind("escape", hl.dsp.submap("reset"))
        end)
        hl.bind(mod .. "R", hl.dsp.submap("resize"))
      '';
    };

    # ── Waybar: add Hyprland modules next to the sway ones ────────────────────
    # The bar itself is defined in 6.sway.nix. Lists merge, so this appends.
    # Waybar disables whichever compositor's module can't connect, so one
    # config serves both sessions.
    programs.waybar.settings.mainBar = {
      modules-left = [ "hyprland/workspaces" "hyprland/submap" ];
      "hyprland/workspaces".format = "{name}";
    };

    # Hyprland marks the focused workspace .active (sway uses .focused)
    programs.waybar.style = lib.mkAfter ''
      #workspaces button.active {
        background-color: ${accent};
        color: ${bg};
      }
      #submap {
        background-color: ${urgent};
        color: ${bg};
        padding: 0 10px;
      }
    '';
  };
}