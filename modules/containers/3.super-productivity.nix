{ ... }:

# ── Super Productivity — to-do & time tracker ──────────────────────────────────
# Web UI: https://todo.home
#
# To add DNS record:
#   echo "192.168.0.252 todo.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{
  virtualisation.oci-containers.containers.super-productivity = {
    image     = "johannesjo/super-productivity:latest";
    autoStart = true;

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.super-productivity.rule=Host(`todo.home`)"
      "--label=traefik.http.routers.super-productivity.entrypoints=websecure"
      "--label=traefik.http.routers.super-productivity.tls=true"
      "--label=traefik.http.routers.super-productivity.tls.certresolver=step"
      "--label=traefik.http.services.super-productivity.loadbalancer.server.port=80"
    ];
  };

  systemd.services.docker-super-productivity = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
