# modules/containers/ryot.nix
{ ... }:

# ── Ryot — media & life tracker ────────────────────────────────────────────────
# Web UI: https://ryot.home
# Tracks books, movies, TV, games, music, workouts, etc.
# Uses ryot-unlocked (pro features, same config as upstream).
#
# ── Secrets (/home/jakub/secrets/ryot.env) ─────────────────────────────────────
# POSTGRES_PASSWORD=<strong password>
# SERVER_ADMIN_ACCESS_TOKEN=<32+ char random string>
#
# Generate with:
#   head /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32 && echo
#
# To add DNS record:
#   echo "192.168.0.252 ryot.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
#
# First 人 to register becomes admin.
# Data lives in /home/jakub/docker-data/ryot-db — back this up!
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/ryot-db 0755 jakub jakub -"
  ];

  # ── Database ─────────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.ryot-db = {
    image     = "postgres:16-alpine";
    autoStart = true;

    environmentFiles = [ "/home/jakub/secrets/ryot.env" ];
    environment = {
      POSTGRES_USER     = "ryot";
      POSTGRES_DB       = "ryot";
    };

    volumes = [
      "/home/jakub/docker-data/ryot-db:/var/lib/postgresql/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--network-alias=ryot-db"
      "--health-cmd=pg_isready -U ryot"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=5"
    ];
  };

  # ── App ───────────────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.ryot = {
    image     = "ghcr.io/dopp1e/ryot-unlocked:sha-ab6ab8c";
    autoStart = true;
    dependsOn = [ "ryot-db" ];

	environmentFiles = [ "/home/jakub/secrets/ryot.env" ];
	environment = {
	  TZ = "Europe/Warsaw";
	};

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.ryot.rule=Host(`ryot.home`)"
      "--label=traefik.http.routers.ryot.entrypoints=websecure"
      "--label=traefik.http.routers.ryot.tls=true"
      "--label=traefik.http.routers.ryot.tls.certresolver=step"
      "--label=traefik.http.services.ryot.loadbalancer.server.port=8000"
    ];
  };

  # ── Ordering ─────────────────────────────────────────────────────────────────
  systemd.services.docker-ryot-db = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };

  systemd.services.docker-ryot = {
    after    = [ "docker-network-traefik.service" "docker-ryot-db.service" ];
    requires = [ "docker-network-traefik.service" "docker-ryot-db.service" ];
  };
}
