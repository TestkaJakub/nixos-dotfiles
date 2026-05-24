{ ... }:

# ── Homarr — homelab dashboard ─────────────────────────────────────────────────
# Web UI: https://homarr.home
# Drag-and-drop dashboard with built-in integrations for Jellyfin, qBittorrent,
# Radarr, Sonarr, Prowlarr and more.
#
# To add DNS record:
#   echo "192.168.0.252 homarr.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/homarr-config 0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.homarr = {
    image     = "ghcr.io/homarr-labs/homarr:latest";
    autoStart = true;

    environment = {
      TZ = "Europe/Warsaw";
    };
    
    environmentFiles = [ "/home/jakub/secrets/homarr.env" ];

    volumes = [
      "/home/jakub/docker-data/homarr-config:/appdata"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.homarr.rule=Host(`homarr.home`)"
      "--label=traefik.http.routers.homarr.entrypoints=websecure"
      "--label=traefik.http.routers.homarr.tls=true"
      "--label=traefik.http.routers.homarr.tls.certresolver=step"
      "--label=traefik.http.services.homarr.loadbalancer.server.port=7575"
    ];
  };

  systemd.services.docker-homarr = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
