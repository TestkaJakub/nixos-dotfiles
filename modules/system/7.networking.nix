{ pkgs, lib, config, ... }:
let
  isServer      = config.profile.isRole [ "server" ];
  isWorkstation = config.profile.isRole [ "workstation" ];
  isPersonal    = config.profile.isRole [ "personal" ];
  isNotServer   = isWorkstation || isPersonal;
  isThinkpad   = isWorkstation || isServer;
in
{
  networking = {
    useDHCP = lib.mkDefault isNotServer;

    networkmanager = lib.mkIf isNotServer {
      enable            = true;
      insertNameservers = if isWorkstation then [ "127.0.0.1" ] else [ "192.168.0.252" ];
      dns               = lib.mkForce "none";
    };

    nameservers =
      if isThinkpad then [ "127.0.0.1" "1.1.1.1" ]
      else [ "192.168.0.252" "1.1.1.1" ];
    
    defaultGateway = lib.mkIf isServer {
      address = "192.168.0.1";
      interface = config.profile.lanInterface;
    };

    interfaces = lib.mkIf isServer {
      ${config.profile.lanInterface}.ipv4.addresses = [{
        address = "192.168.0.252";
        prefixLength = 24;
      }];
    };

    firewall = if isServer then {
      enable          = true;
      allowedTCPPorts = [ 53 445 139 22 ];
      allowedUDPPorts = [ 53 137 138 ];

      interfaces = {
        tailscale0.allowedTCPPorts                     = [ 80 443 8080 8053 9000 ];
        ${config.profile.lanInterface}.allowedTCPPorts = [ 53 445 139 ];
      };
    } else {
      enable = true;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };

    hosts = lib.mkIf isWorkstation {
      "127.0.0.1" = [
        "homarr.home"
        "todo.home"
        "jellyfin.home"
        "jellyseerr.home"
        "radarr.home"
        "sonarr.home"
        "lidarr.home"
        "bazarr.home"
        "prowlarr.home"
        "qbittorrent.home"
        "pihole.home"
        "traefik.home"
        "portainer.home"
        "immich.home"
        "firefly.home"
        "searxng.home"
        "ryot.home"
        "resume.home"
        "homelable.home"
      ];
    };
  };

  services.resolved = {
    enable = true;
    domains     = lib.mkIf isNotServer [ "~." ];
    fallbackDns = lib.mkIf isNotServer [ "1.1.1.1" ];
    extraConfig =
      if isServer then "DNSStubListener=no"
      else ''
        DNS=${if isWorkstation then "127.0.0.1" else "192.168.0.252"}
        Domains=~.
      '';
  };

  services.mullvad-vpn = lib.mkIf isNotServer {
    enable  = true;
    package = pkgs.mullvad-vpn;
  };

  security.pki.certificateFiles = [
	  ../meta/homelab-root.crt
	];
}