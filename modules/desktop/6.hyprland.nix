{ pkgs, config, inputs, ... }:

# ── Hyprland — backup compositor ───────────────────────────────────────────────
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

  isPersonal = config.profile.isRole [ "personal" ];
    nvidiaPatch = if isPersonal then ''
      # ── Nvidia (GTX 660, legacy 470 driver) ──────────────────────────────────
      env = LIBVA_DRIVER_NAME,nvidia
      env = __GLX_VENDOR_LIBRARY_NAME,nvidia
      env = NVD_BACKEND,direct
      env = GBM_BACKEND,nvidia-drm
      env = __NV_PRIME_RENDER_OFFLOAD,1
      cursor {
        no_hardware_cursors = true
      }
    '' else "";
in
{
  programs.hyprland.enable = true;

  home-manager.users.${user} = {
    home.pointerCursor = {
      name    = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size    = 24;
    };

    xdg.configFile."hypr/hyprland.conf".text = ''
      ${nvidiaPatch}
      # ── Monitors ────────────────────────────────────────────────────────────
      monitor = ,preferred,auto,1

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

      # ── Cursor ──────────────────────────────────────────────────────────────
      env = XCURSOR_THEME,Bibata-Modern-Classic
      env = XCURSOR_SIZE,24

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

      # close window
      bind = SUPER, E, killactive

      # focus
      bind = SUPER, A, movefocus, l
      bind = SUPER, D, movefocus, r
      bind = SUPER, W, movefocus, u
      bind = SUPER, S, movefocus, d

      # cycle focus
      bind = SUPER, Tab, cyclenext

      # window state
      bind = SUPER, X, fullscreen,    1
      bind = SUPER, V, fullscreen,    0
      bind = SUPER, C, togglefloating

      # move windows
      bind = SUPER, K, movewindow, u
      bind = SUPER, J, movewindow, d
      bind = SUPER, H, movewindow, l
      bind = SUPER, L, movewindow, r

      # move window to monitor — use explicit monitor names
      bind = SUPER ALT, H, movewindow, mon:eDP-1
      bind = SUPER ALT, L, movewindow, mon:HDMI-A-1

      # workspaces
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
