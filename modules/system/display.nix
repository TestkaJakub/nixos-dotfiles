{ pkgs, lib, ... }:

# ── Display & session ──────────────────────────────────────────────────────────
{
  services.displayManager = {
    enable = true;
    sddm   = {
      enable         = true;
      wayland.enable = true;
    };
  };

  xdg.portal = {
    enable       = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  # xdg-desktop-portal-wlr has a ConditionEnvironment guard that prevents it
  # from starting outside a recognised compositor session name. MangoWC is not
  # on that list, so we clear the condition to let it start unconditionally.
  systemd.user.services.xdg-desktop-portal-wlr = {
    overrideStrategy            = "asDropin";
    unitConfig.ConditionEnvironment = lib.mkForce "";
  };

  # Wayland session environment variables — set system-wide so they are
  # present for all processes, including those launched by SDDM.
  environment.sessionVariables = {
    NIXOS_OZONE_WL      = "1";
    XDG_CURRENT_DESKTOP = "wlroots";
    MOZ_ENABLE_WAYLAND  = "1";
    OZONE_PLATFORM      = "wayland";
  };
}
