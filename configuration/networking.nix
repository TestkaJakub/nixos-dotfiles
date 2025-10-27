{ config, lib, host, ... }:

{
  networking = {
    hostName = ${host};
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.enable = true;
  };
}
