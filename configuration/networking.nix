{ config, lib, host, ... }:

{
  networking = {
    hostName = host;
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = true;
      allowedTCPPorts = [5900 8081 8082 19000 19001];
      extraCommands = ''
      	for port in 59000 8081 8082 19000 19001; do
          iptables -A nixos-fw -p tcp -s 192.168.0.0/24 --dport $port -s 192.168.0.0/24 -j nixos-fw-accept
	done
      '';
    };
  };
}
