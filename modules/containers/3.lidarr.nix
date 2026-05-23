{ ... }:

# ── Lidarr — music automation ──────────────────────────────────────────────────
# Web UI: https://lidarr.home
# To add DNS record:
#   echo "192.168.0.252 lidarr.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/lidarr-config 0755 jakub jakub -"
    "d /home/jakub/data/media/music                  0775 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.lidarr = {
    image     = "lscr.io/linuxserver/lidarr:latest";
    autoStart = true;

    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ   = "Europe/Warsaw";
    };

    volumes = [
      "/home/jakub/docker-data/lidarr-config:/config"
      "/home/jakub/data:/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.lidarr.rule=Host(`lidarr.home`)"
      "--label=traefik.http.routers.lidarr.entrypoints=websecure"
      "--label=traefik.http.routers.lidarr.tls=true"
      "--label=traefik.http.routers.lidarr.tls.certresolver=step"
      "--label=traefik.http.services.lidarr.loadbalancer.server.port=8686"
    ];
  };

  systemd.services.docker-lidarr = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
