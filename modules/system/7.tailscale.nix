{ pkgs, config, lib, ... }:

# ── Tailscale ──────────────────────────────────────────────────────────────────
# Server advertises LAN subnet so Tailscale devices can reach 192.168.0.0/24.
# Workstation/personal get Trayscale tray GUI for connect/disconnect.
let
  isServer    = config.profile.isRole [ "server" ];
  isNotServer = !isServer;
  user        = config.profile.username;
in
{
  services.tailscale = {
    enable             = true;
    useRoutingFeatures = "both";
    extraUpFlags       = lib.mkIf isServer [
      "--advertise-routes=192.168.0.0/24"
      "--accept-dns=false"
    ];
  };

  boot.kernel.sysctl = lib.mkIf isServer {
    "net.ipv4.ip_forward"          = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts   = [ config.services.tailscale.port ];
    checkReversePath  = "loose";
  };

  environment.systemPackages = [ pkgs.tailscale ];

  home-manager.users.${user}.home.packages = lib.mkIf isNotServer [ pkgs.trayscale ];
}