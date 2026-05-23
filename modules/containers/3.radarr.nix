{ ... }:

# ── Radarr — movie automation ──────────────────────────────────────────────────
# Monitors for new movies, grabs them via Prowlarr, sends to qBittorrent.
# Web UI: https://radarr.home
#
# To add DNS record:
#   echo "192.168.0.252 radarr.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/radarr-config 0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.radarr = {
    image     = "lscr.io/linuxserver/radarr:latest";
    autoStart = true;

    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ   = "Europe/Warsaw";
    };

    volumes = [
      "/home/jakub/docker-data/radarr-config:/config"
      "/home/jakub/data:/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.radarr.rule=Host(`radarr.home`)"
      "--label=traefik.http.routers.radarr.entrypoints=websecure"
      "--label=traefik.http.routers.radarr.tls=true"
      "--label=traefik.http.routers.radarr.tls.certresolver=step"
      "--label=traefik.http.services.radarr.loadbalancer.server.port=7878"
    ];
  };

  systemd.services.docker-radarr = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
