{ pkgs, lib, config, ... }:

# ── Display & session ──────────────────────────────────────────────────────────
# KDE Plasma 6 takes over most of what this file used to configure.
# The plasma.nix module sets up SDDM and the Wayland session.
#
# What remains here: dconf enable (for GTK apps), and the Nvidia env vars
# for the personal/desktop role (GTX 660 legacy 470 driver).
#
# The sddm-astronaut custom theme, xdg-desktop-portal-wlr, and the
# systemd override for the wlr portal have been removed — KDE ships its
# own portal (xdg-desktop-portal-kde) and its own login theme.
{
  services.dbus.packages = [ pkgs.dconf ];
  programs.dconf.enable  = true;
}
