{ config, lib, host, ... }:

{
  networking = {
    hostName = host;
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall {
      enable = ture;
      allowedTCPPorts = [];
      allowedTCPPortRanges = [
        { from = 5900; to = 5900; }
      ];
      extraCommands = ''
        iptables -A nixos-fw -p tcp --dport 5900 -s 192.168.0.0/24 -j nixos-fw-accept
      '';
    };
  };
}
