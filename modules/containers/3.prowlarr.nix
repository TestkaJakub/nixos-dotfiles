{ ... }:

# ── Prowlarr — indexer manager ─────────────────────────────────────────────────
# Manages torrent indexers for Radarr and Sonarr.
# Web UI: https://prowlarr.home
#
# To add DNS record:
#   echo "192.168.0.252 prowlarr.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/prowlarr-config 0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.prowlarr = {
    image     = "lscr.io/linuxserver/prowlarr:latest";
    autoStart = true;

    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ   = "Europe/Warsaw";
    };

    volumes = [
      "/home/jakub/docker-data/prowlarr-config:/config"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.prowlarr.rule=Host(`prowlarr.home`)"
      "--label=traefik.http.routers.prowlarr.entrypoints=websecure"
      "--label=traefik.http.routers.prowlarr.tls=true"
      "--label=traefik.http.routers.prowlarr.tls.certresolver=step"
      "--label=traefik.http.services.prowlarr.loadbalancer.server.port=9696"
    ];
  };

  systemd.services.docker-prowlarr = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
