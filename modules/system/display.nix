{ pkgs, lib, config, ... }:

# ── Display & session ──────────────────────────────────────────────────────────
let
  t = config.theme;

  sddm-theme = pkgs.sddm-astronaut.override {
    themeConfig = {
      AccentColor          = t.palette.primary;
      BackgroundColor      = t.palette.secondary;
      HoverColor           = t.functions.lighten t.palette.secondary 0.05;
      FontColor            = t.functions.textcolor t.palette.secondary;
      PlaceholderColor     = t.functions.darken t.palette.primary 0.2;
      FormPosition         = "center";
      HideCompletePassword = false;
      Background           = config.meta.defaults.wallpaper;
    };
  };
in
{
  services.displayManager = {
    enable = true;
    sddm = {
      enable        = true;
      wayland.enable = true;
      package       = pkgs.kdePackages.sddm;
      theme         = "sddm-astronaut-theme";
      extraPackages = [
        sddm-theme
        pkgs.kdePackages.qtmultimedia
        pkgs.kdePackages.qtsvg
      ];
    };
  };

  environment.systemPackages = [ sddm-theme ];

  xdg.portal = {
    enable       = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  systemd.user.services.xdg-desktop-portal-wlr = {
    overrideStrategy                = "asDropin";
    unitConfig.ConditionEnvironment = lib.mkForce "";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    OZONE_PLATFORM = "wayland";
  };
}
