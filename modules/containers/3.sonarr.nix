{ ... }:

# ── Sonarr — TV show automation ────────────────────────────────────────────────
# Monitors for new episodes, grabs them via Prowlarr, sends to qBittorrent.
# Web UI: https://sonarr.home
#
# To add DNS record:
#   echo "192.168.0.252 sonarr.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/sonarr-config 0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.sonarr = {
    image     = "lscr.io/linuxserver/sonarr:latest";
    autoStart = true;

    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ   = "Europe/Warsaw";
    };

    volumes = [
      "/home/jakub/docker-data/sonarr-config:/config"
      "/home/jakub/data:/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.sonarr.rule=Host(`sonarr.home`)"
      "--label=traefik.http.routers.sonarr.entrypoints=websecure"
      "--label=traefik.http.routers.sonarr.tls=true"
      "--label=traefik.http.routers.sonarr.tls.certresolver=step"
      "--label=traefik.http.services.sonarr.loadbalancer.server.port=8989"
    ];
  };

  systemd.services.docker-sonarr = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
