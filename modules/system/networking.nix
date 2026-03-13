{ pkgs, lib, config, ... }:

# ── Networking ─────────────────────────────────────────────────────────────────
{
  networking = {
    networkmanager.enable = true;
    useDHCP               = lib.mkDefault true;

    firewall = {
      enable          = true;
      allowedTCPPorts = [ 3456 5900 8081 8082 19000 19001 ];

      # Restrict all non-essential ports to LAN only
      extraCommands = ''
        for port in 5900 8081 8082 19000 19001; do
          iptables -A nixos-fw -p tcp -s 192.168.0.0/24 --dport $port -j nixos-fw-accept
        done
      '';
    };
  };

  services.resolved.enable = true;

  services.mullvad-vpn = {
    enable  = true;
    package = pkgs.mullvad-vpn;
  };

  # SSH — LAN only, no root login
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin    = "no";
      PasswordAuthentication = false;
    };
    listenAddresses = [{ addr = "192.168.0.0"; port = 22; }];
  };
}
