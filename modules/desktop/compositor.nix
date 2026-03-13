{ pkgs, config, inputs, ... }:

# ── Compositor (MangoWC) ───────────────────────────────────────────────────────
# Reads: config.theme.{palette, functions}
#        config.locale.{keyboardLayout, latitude, longitude}
#        config.profile.username
#        config.meta.defaults.{browser, terminal, fileManager}
let
  cfg  = config.theme;
  loc  = config.locale;
  meta = config.meta.defaults;
  user = config.profile.username;

  mangoConfig = ''
    monitorrule=eDP-1,0.55,1,title,0,1,0,0,1920,1080,60
    monitorrule=HDMI-A-1,0.55,1,title,0,1,1925,0,1920,1080,60

    bind=super,r,reload_config
    bind=super,q,spawn,${meta.terminal}
    bind=super,b,spawn,${meta.browser}
    bind=super,f,spawn,fuzzel
    bind=super,code:107,spawn,screenshot-region
    bind=super,e,killclient
    bind=super,n,spawn,${meta.fileManager}

    bind=super,Tab,focusstack,next

    bind=super,a,focusdir,left
    bind=super,d,focusdir,right
    bind=super,w,focusdir,up
    bind=super,s,focusdir,down

    bind=super,x,togglefullscreen
    bind=super,v,togglemaxmizescreen
    bind=super,c,togglefloating

    bind=super,1,comboview,1
    bind=super,2,comboview,2
    bind=super,3,comboview,3
    bind=super,4,comboview,4
    bind=super,5,comboview,5
    bind=super,6,comboview,6
    bind=super,7,comboview,7
    bind=super,8,comboview,8
    bind=super,9,comboview,9

    bind=super,t,setlayout,tile
    bind=super,y,setlayout,vertical_grid
    bind=super,u,setlayout,spiral
    bind=super,i,setlayout,scroller
    bind=super,o,switch_layout
    bind=super,p,togglegaps

    bind=super,k,exchange_client,up
    bind=super,j,exchange_client,down
    bind=super,h,exchange_client,left
    bind=super,l,exchange_client,right

    bind=super+alt,h,tagmon,left,1
    bind=super+alt,l,tagmon,right,1

    bind=super,g,spawn,bash kbm
    bind=super,m,spawn,bash cpc
    bind=ALT,m,spawn,${pkgs.wayvnc}/bin/wayvnc 0.0.0.0 5900

    bind=none,XF86AudioMute,spawn,pamixer -t
    bind=none,XF86AudioLowerVolume,spawn,pamixer --allow-boost -d 5
    bind=none,XF86AudioRaiseVolume,spawn,pamixer --allow-boost -i 5

    focuscolor=${cfg.functions.toMango cfg.palette.primary}
    bordercolor=${cfg.functions.toMango cfg.palette.secondary}

    xkb_rules_layout=${loc.keyboardLayout}
    xkb_layout=${loc.keyboardLayout}
  '';

  autostartScript = ''
    #!/usr/bin/env bash
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=wlroots
    export XDG_SESSION_DESKTOP=wlroots

    export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE

    (
      sleep 2
      systemctl --user restart xdg-desktop-portal-wlr.service xdg-desktop-portal.service
    ) &
    sleep 2

    hyprpaper --config ~/.config/hypr/hyprpaper.conf &
    mako &
    waybar &
    gammastep -m wayland -l ${toString loc.latitude}:${toString loc.longitude} -t 6000:3700 &
  '';
in
{
  programs.mango.enable = true;

  home-manager.users.${user} = {
    home.packages = [ inputs.mangowc.packages.x86_64-linux.default ];

    xdg.configFile."mango/config.conf".text = mangoConfig;

    xdg.configFile."mango/autostart.sh" = {
      text       = autostartScript;
      executable = true;
    };

    xdg.dataFile."wayland-sessions/mangowc.desktop".text = ''
      [Desktop Entry]
      Name=MangoWC
      Comment=Mango window manager
      Exec=mangowc --config ~/.config/mango/config.conf
      Type=Application
      DesktopNames=MangoWC
    '';

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html"                 = [ meta.browserDesktop ];
        "x-scheme-handler/http"    = [ meta.browserDesktop ];
        "x-scheme-handler/https"   = [ meta.browserDesktop ];
        "x-scheme-handler/about"   = [ meta.browserDesktop ];
        "x-scheme-handler/unknown" = [ meta.browserDesktop ];
        "inode/directory"          = [ meta.fileManagerDesktop ];
      };
    };
  };
}
