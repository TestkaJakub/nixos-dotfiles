{ pkgs, config, lib, ... }:

# ── Tailscale ──────────────────────────────────────────────────────────────────
# Mesh VPN for secure remote access to this machine and all services.
# Accessible via https://<tailscale-ip>:<port> from any device on the tailnet.
#
# First-time setup (run once after rebuild):
#   sudo tailscale up --advertise-exit-node   # optional: use as exit node
#   sudo tailscale up                         # basic auth, opens browser URL
#
# Useful commands:
#   tailscale status          — show connected devices
#   tailscale ip              — show this machine's tailscale IP
#   tailscale ping <host>     — check connectivity to another tailnet device
{
  services.tailscale = {
    enable     = true;
    useRoutingFeatures = "both";   # allows exit node + subnet routing
  };

  # Open firewall for Tailscale
  networking.firewall = {
    trustedInterfaces          = [ "tailscale0" ];
    allowedUDPPorts            = [ config.services.tailscale.port ];
    checkReversePath           = "loose";   # required for Tailscale to work
  };

  # Persist Tailscale state across reboots
  environment.systemPackages = [ pkgs.tailscale ];
}
