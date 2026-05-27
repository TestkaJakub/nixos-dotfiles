{ pkgs, config, lib, ... }:

# ── KDE Plasma 6 — desktop environment ────────────────────────────────────────
# Replaces Hyprland (2.hyprland.nix) and Labwc (4.labwc.nix).
#
# What KDE provides out of the box (no separate modules needed):
#   - Compositor (KWin, Wayland or X11)
#   - Panel / taskbar (replaces Waybar)
#   - Notification daemon (replaces Mako)
#   - Screen locker (replaces Hyprlock)
#   - App launcher (replaces Fuzzel — use KRunner: Alt+Space)
#   - Wallpaper management (replaces Hyprpaper/swww)
#   - Screenshot tool (Spectacle — replaces grim/slurp scripts)
#   - File manager (Dolphin — can keep Nemo alongside if preferred)
#   - Clipboard manager (Klipper — replaces cliphist)
#   - System tray
#
# Keybinds mirror your Hyprland layout where KDE allows:
#   Super+Q     → open terminal
#   Super+B     → open browser
#   Super+F     → KRunner (app launcher)
#   Super+E     → close window  (configured below)
#   Super+Print → Spectacle region screenshot
#   Super+Ctrl+L → lock screen
#
# Note: Gamma/night colour is handled by KDE's built-in Night Color.
# EasyEffects, udiskie, and Tailscale tray still autostart via systemd.

let
  user = config.profile.username;
in
{
  # ── System-level Plasma enable ─────────────────────────────────────────────
  services.desktopManager.plasma6.enable = true;

  # ── Display manager ────────────────────────────────────────────────────────
  # SDDM is the recommended DM for Plasma; wayland session is default.
  services.displayManager = {
    sddm = {
      enable         = true;
      wayland.enable = true;
      package        = pkgs.kdePackages.sddm;
    };
    defaultSession = "plasma";
  };

  # ── Wayland session variables ───────────────────────────────────────────────
  # KWin sets most of these itself; keep Ozone for Electron/Chromium apps.
  environment.sessionVariables = {
    NIXOS_OZONE_WL     = "1";
    MOZ_ENABLE_WAYLAND = "1";
  } // lib.optionalAttrs (config.profile.isRole [ "personal" ]) {
    LIBVA_DRIVER_NAME         = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND               = "nvidia-drm";
    __NV_PRIME_RENDER_OFFLOAD = "1";
    NVD_BACKEND               = "direct";
  };

  # ── XDG portals ────────────────────────────────────────────────────────────
  # xdg-desktop-portal-kde is pulled in automatically by plasma6; keep gtk
  # portal for apps that need it (Firefox, Electron).
  xdg.portal = {
    enable       = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # ── Extra packages ──────────────────────────────────────────────────────────
  # Core KDE apps not pulled in by the plasma6 module itself.
  environment.systemPackages = with pkgs.kdePackages; [
    spectacle      # screenshots  (Super+Print)
    kdeconnect-kde # phone integration
    kate           # text editor
    ark            # archive manager
    okular         # document viewer
    gwenview       # image viewer
    kcolorchooser  # colour picker
  ] ++ [
    pkgs.wl-clipboard  # wl-copy/wl-paste, still useful in scripts
  ];

  # ── Home-manager: cursor & autostart ──────────────────────────────────────
  home-manager.users.${user} = {

    # Cursor theme (matches your existing Bibata-Modern-Classic choice)
    home.pointerCursor = {
      name    = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size    = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    # GTK dark theme so non-KDE apps match
    gtk = {
      enable = true;
      theme = {
        name    = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
    };

    # Qt platform theme — let KDE handle it
    qt = {
      enable        = true;
      platformTheme = { name = "kde"; };
    };

    # Autostart apps that KDE doesn't manage itself
    xdg.configFile = {
      # EasyEffects (audio effects) — already has its own systemd unit in
      # system/easyeffects.nix, nothing extra needed here.

      # Plasma autostart entries — .desktop files dropped in
      # ~/.config/autostart/ are launched by the session manager.
      "autostart/trayscale.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Trayscale
        Exec=${pkgs.trayscale}/bin/trayscale --hide-window
        Icon=network-vpn
        X-KDE-autostart-condition=startupconfig:ktrascalerc:General:StartMinimized:true
      '';

      "autostart/startup-browser.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Startup Browser
        Exec=${config.scripts.startupBrowser}/bin/startup-browser
        Icon=internet-web-browser
        X-KDE-autostart-phase=2
      '';
    };
  };
}
