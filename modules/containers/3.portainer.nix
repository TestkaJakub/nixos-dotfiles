{ ... }:

# ── Portainer — Docker management UI ──────────────────────────────────────────
# Web UI: https://portainer.home
#
# To add DNS record:
#   echo "192.168.0.252 portainer.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
#
# First visit: create your admin account within 5 minutes or the instance locks.
# Data lives in /home/jakub/docker-data/portainer-data — back this up!
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/portainer-data 0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.portainer = {
    image     = "portainer/portainer-ce:latest";
    autoStart = true;

    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "/home/jakub/docker-data/portainer-data:/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.portainer.rule=Host(`portainer.home`)"
      "--label=traefik.http.routers.portainer.entrypoints=websecure"
      "--label=traefik.http.routers.portainer.tls=true"
      "--label=traefik.http.routers.portainer.tls.certresolver=step"
      "--label=traefik.http.services.portainer.loadbalancer.server.port=9000"
    ];
  };

  systemd.services.docker-portainer = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
