{ ... }:

# ── Jellyfin — media server ────────────────────────────────────────────────────
# Web UI: https://jellyfin.home
# Media lives on /home/jakub/data/media (LVM storage disk)
#
# To add DNS record:
#   echo "192.168.0.252 jellyfin.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{
	systemd.tmpfiles.rules = [
	  "d /home/jakub/docker-data/jellyfin-config 0755 jakub jakub -"
	  "d /home/jakub/data/media                          0775 jakub jakub -"
	  "d /home/jakub/data/media/movies                   0775 jakub jakub -"
	  "d /home/jakub/data/media/tv                       0775 jakub jakub -"
	  "d /home/jakub/data/media/music                    0775 jakub jakub -"
	  "d /home/jakub/data/media/books                    0775 jakub jakub -"
	  "d /home/jakub/data/media/adult                    0775 jakub jakub -"
	];

  virtualisation.oci-containers.containers.jellyfin = {
    image     = "jellyfin/jellyfin:latest";
    autoStart = true;

    environment = {
      JELLYFIN_PublishedServerUrl = "https://jellyfin.home";
    };

    volumes = [
      "/home/jakub/docker-data/jellyfin-config:/config"
      "/home/jakub/data/media:/media"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.jellyfin.rule=Host(`jellyfin.home`)"
      "--label=traefik.http.routers.jellyfin-http.rule=Host(`jellyfin.home`)"
      "--label=traefik.http.routers.jellyfin.entrypoints=websecure"
      "--label=traefik.http.routers.jellyfin-http.entrypoints=web"
      "--label=traefik.http.routers.jellyfin-http.service=jellyfin"
      "--label=traefik.http.routers.jellyfin.tls=true"
      "--label=traefik.http.routers.jellyfin.tls.certresolver=step"
      "--label=traefik.http.services.jellyfin.loadbalancer.server.port=8096"
    ];
  };

  systemd.services.docker-jellyfin = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
