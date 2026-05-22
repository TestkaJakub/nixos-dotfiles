{ pkgs, config, lib, ... }:

# ── Tailscale ──────────────────────────────────────────────────────────────────
# Mesh VPN for secure remote access.
# Trayscale provides a GTK system tray GUI for connect/disconnect.
#
# First-time setup (run once after rebuild):
#   sudo tailscale up
#
# Useful commands:
#   tailscale status          — show connected devices
#   tailscale ip              — show this machine's tailscale IP
let
  user = config.profile.username;
in
{
  services.tailscale = {
    enable             = true;
    useRoutingFeatures = "both";
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts   = [ config.services.tailscale.port ];
    checkReversePath  = "loose";
  };

  environment.systemPackages = [ pkgs.tailscale ];

  # Trayscale — GTK tray GUI for Tailscale
  home-manager.users.${user}.home.packages = [ pkgs.trayscale ];
}
