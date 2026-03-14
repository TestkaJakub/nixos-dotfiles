{ pkgs, lib, ... }:

# ── Networking ─────────────────────────────────────────────────────────────────
{
  networking = {
    networkmanager.enable = true;
    useDHCP               = lib.mkDefault true;

    firewall = {
      enable          = true;

      # Port 3456: Vikunja web UI — open globally (localhost-only in practice,
      # but exposed here so the service is reachable from LAN if needed).
      allowedTCPPorts = [ 3456 ];

      # LAN-only ports — restricted to the 192.168.0.0/24 subnet.
      # Using extraPackages + allowedTCPPortRanges isn't expressive enough for
      # per-source rules, so we use the interfaces-based alternative:
      #   allowedTCPPorts applies globally;
      #   the per-interface override below scopes the LAN ports correctly.
      #
      # These are declared via interfaces."".allowedTCPPorts so NixOS generates
      # proper nftables/iptables rules with no duplication across rebuilds.
      interfaces."eno1" = {
        allowedTCPPorts = [ 5900 8081 8082 19000 19001 ];
      };

      # If your LAN-facing interface is named differently (e.g. wlp3s0, eth0),
      # change "eno1" above or add another interfaces block.
    };
  };

  services.resolved.enable = true;

  services.mullvad-vpn = {
    enable  = true;
    package = pkgs.mullvad-vpn;
  };
}
