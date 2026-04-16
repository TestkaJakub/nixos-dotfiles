{ pkgs, config, ... }:

# ── Hyprland — backup compositor ───────────────────────────────────────────────
# Fallback Wayland compositor selectable from the SDDM session picker.
# Keybinds mirror compositor.nix (MangoWC) as closely as Hyprland allows.
#
# Notable differences from MangoWC:
#   - Layout switching (tile/vertical_grid/spiral/scroller) → not applicable,
#     Hyprland uses its own layout system (dwindle by default)
#   - comboview (workspaces) → mapped to standard Hyprland workspaces
#   - exchange_client / focusdir → mapped to movefocus / movewindow
#   - tagmon → movewindow to monitor
#   - togglemaxmizescreen → fullscreen 1 (maximized, not true fullscreen)
#   - togglegaps → togglegaps (same name, works in Hyprland)
#
# To remove once MangoWC is fixed: delete this file and rebuild.
let
  meta = config.meta.defaults;
  loc  = config.locale;
  user = config.profile.username;

  hyprlock  = "${pkgs.hyprlock}/bin/hyprlock";
  cliphist  = "${pkgs.cliphist}/bin/cliphist";
  wlCopy    = "${pkgs.wl-clipboard}/bin/wl-copy";
  pamixer   = "${pkgs.pamixer}/bin/pamixer";
  hyprpaper = "${pkgs.hyprpaper}/bin/hyprpaper";
  mako      = "${pkgs.mako}/bin/mako";
  waybar    = "${pkgs.waybar}/bin/waybar";
  gammastep = "${pkgs.gammastep}/bin/gammastep";
  wlPaste   = "${pkgs.wl-clipboard}/bin/wl-paste";

  browser     = "${meta.browserPackage}/bin/${meta.browser}";
  terminal    = "${meta.terminalPackage}/bin/${meta.terminal}";
  fileManager = "${meta.fileManagerPackage}/bin/${meta.fileManager}";
  fuzzel      = "${meta.fuzzel}/bin/fuzzel";
in
{
  programs.hyprland.enable = true;

  home-manager.users.${user} = {
    xdg.configFile."hypr/hyprland.conf".text = ''
      # ── Monitors ────────────────────────────────────────────────────────────
      monitor = eDP-1,    1920x1080@60, 0x0,    1
      monitor = HDMI-A-1, 1920x1080@60, 1925x0, 1

      # ── Autostart ───────────────────────────────────────────────────────────
      exec-once = ${hyprpaper} --config ~/.config/hypr/hyprpaper.conf
      exec-once = ${mako}
      exec-once = ${waybar}
      exec-once = ${gammastep} -m wayland -l ${toString loc.latitude}:${toString loc.longitude} -t 6000:3700
      exec-once = ${wlPaste} --type text  --watch ${cliphist} store
      exec-once = ${wlPaste} --type image --watch ${cliphist} store
      exec-once = ${config.scripts.startupBrowser}/bin/startup-browser

      # ── Input ───────────────────────────────────────────────────────────────
      input {
        kb_layout = ${loc.keyboardLayout}
        follow_mouse = 1
      }

      # ── General ─────────────────────────────────────────────────────────────
      general {
        gaps_in  = 4
        gaps_out = 8
        border_size = 1
        layout = dwindle
      }

      # ── Keybinds ────────────────────────────────────────────────────────────
      # spawn
      bind = SUPER,       Q,     exec, ${terminal}
      bind = SUPER,       B,     exec, ${browser}
      bind = SUPER,       F,     exec, ${fuzzel}
      bind = SUPER,       N,     exec, ${fileManager}
      bind = SUPER,       Print, exec, screenshot-region
      bind = SUPER CTRL,  L,     exec, ${hyprlock}
      bind = SUPER CTRL,  D,     exec, ${config.scripts.dpt}/bin/dpt
      bind = SUPER CTRL,  T,     exec, trayscale
      bind = SUPER SHIFT, V,     exec, bash -c '${cliphist} list | ${fuzzel} --dmenu | ${cliphist} decode | ${wlCopy}'
      bind = SUPER,       G,     exec, ${config.scripts.kbm}/bin/kbm
      bind = SUPER,       M,     exec, ${config.scripts.cpc}/bin/cpc
      bind = ALT,         M,     exec, ${config.scripts.cpcs}/bin/cpcs

      # close window (killclient → killactive)
      bind = SUPER, E, killactive

      # focus (focusdir → movefocus)
      bind = SUPER, A, movefocus, l
      bind = SUPER, D, movefocus, r
      bind = SUPER, W, movefocus, u
      bind = SUPER, S, movefocus, d

      # cycle focus (focusstack next → cyclenext)
      bind = SUPER, Tab, cyclenext

      # window state
      bind = SUPER, X, fullscreen,    1   # togglemaxmizescreen
      bind = SUPER, V, fullscreen,    0   # togglefullscreen
      bind = SUPER, C, togglefloating

      # move windows (exchange_client → movewindow)
      bind = SUPER, K, movewindow, u
      bind = SUPER, J, movewindow, d
      bind = SUPER, H, movewindow, l
      bind = SUPER, L, movewindow, r

      # move window to monitor (tagmon)
      bind = SUPER ALT, H, movewindow, mon:l
      bind = SUPER ALT, L, movewindow, mon:r

      # workspaces (comboview → workspace)
      bind = SUPER, 1, workspace, 1
      bind = SUPER, 2, workspace, 2
      bind = SUPER, 3, workspace, 3
      bind = SUPER, 4, workspace, 4
      bind = SUPER, 5, workspace, 5
      bind = SUPER, 6, workspace, 6
      bind = SUPER, 7, workspace, 7
      bind = SUPER, 8, workspace, 8
      bind = SUPER, 9, workspace, 9

      # audio
      bind = , XF86AudioMute,        exec, ${pamixer} -t
      bind = , XF86AudioLowerVolume, exec, ${pamixer} --allow-boost -d 5
      bind = , XF86AudioRaiseVolume, exec, ${pamixer} --allow-boost -i 5
    '';
  };
}
