{ pkgs, lib, config, ... }:

# ── Networking ─────────────────────────────────────────────────────────────────
# Reads: config.profile.hostname (set in system/nix.nix via networking.hostName)
{
  networking = {
    networkmanager.enable = true;
    useDHCP               = lib.mkDefault true;

    firewall = {
      enable          = true;
      # Port 3456: Vikunja web UI
      # Port 5900: wayvnc
      # Ports 8081-8082, 19000-19001: Expo / React Native dev server
      allowedTCPPorts = [ 3456 5900 8081 8082 19000 19001 ];

      # Restrict most ports to LAN only
      extraCommands = ''
        for port in 5900 8081 8082 19000 19001; do
          iptables -A nixos-fw -p tcp -s 192.168.0.0/24 --dport $port -j nixos-fw-accept
        done
      '';
    };
  };

  # systemd-resolved for DNS
  services.resolved.enable = true;

  # Mullvad VPN (GUI client + daemon)
  services.mullvad-vpn = {
    enable  = true;
    package = pkgs.mullvad-vpn;
  };

  # SSH — enabled for LAN access; root login kept for emergency recovery
  services.openssh = {
    enable   = true;
    settings.PermitRootLogin = "yes";
  };
}
