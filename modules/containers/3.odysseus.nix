{ ... }:

# ── Odysseus AI — self-hosted AI workspace ─────────────────────────────────────
# Web UI: https://odysseus.home
#
# To add DNS record:
#   echo "192.168.0.252 odysseus.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
#
# First login: check logs for the generated admin password:
#   docker compose logs odysseus | grep -i password
# Default username: admin
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/odysseus 0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.odysseus = {
    image     = "pewdiepie-archdaemon/odysseus:latest";
    autoStart = true;

    environment = {
      TZ = "Europe/Warsaw";
    };

    volumes = [
      "/home/jakub/docker-data/odysseus:/app/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.odysseus.rule=Host(`odysseus.home`)"
      "--label=traefik.http.routers.odysseus.entrypoints=websecure"
      "--label=traefik.http.routers.odysseus.tls=true"
      "--label=traefik.http.routers.odysseus.tls.certresolver=step"
      "--label=traefik.http.services.odysseus.loadbalancer.server.port=7000"
    ];
  };

  systemd.services.docker-odysseus = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}