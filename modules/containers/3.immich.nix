# ── Immich — photo & video backup ─────────────────────────────────────────────
# Web UI: https://immich.home
#
# ── Secrets (/home/jakub/secrets/immich.env) ──────────────────────────────────
# DB_PASSWORD=<strong password>
# IMMICH_MACHINE_LEARNING_URL=http://immich-machine-learning:3003
#
# Generate DB_PASSWORD:
#   head /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32 && echo
#
# ── First run ─────────────────────────────────────────────────────────────────
# Visit https://immich.home and create your admin account.
# Data lives in /home/jakub/docker-data/immich-db — back this up!
#
# To add DNS record:
#   echo "192.168.0.252 immich.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{ pkgs, ... }:
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/immich-data    0755 jakub jakub -"
    "d /home/jakub/docker-data/immich-db      0755 jakub jakub -"
    "d /home/jakub/data/photos                        0775 jakub jakub -"
  ];

  # ── PostgreSQL + pgvecto.rs ──────────────────────────────────────────────────
  virtualisation.oci-containers.containers.immich-db = {
    image     = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0";
    autoStart = true;

    environmentFiles = [ "/home/jakub/secrets/immich.env" ];
    environment = {
      POSTGRES_USER     = "immich";
      POSTGRES_DB       = "immich";
      POSTGRES_INITDB_ARGS = "--data-checksums";
    };

    volumes = [
      "/home/jakub/docker-data/immich-db:/var/lib/postgresql/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--network-alias=immich-db"
      "--health-cmd=pg_isready -U immich -d immich"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=10"
    ];
  };

  # ── Redis ────────────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.immich-redis = {
    image     = "redis:7-alpine";
    autoStart = true;

    extraOptions = [
      "--network=traefik"
      "--network-alias=immich-redis"
      "--health-cmd=redis-cli ping"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=10"
    ];
  };

  # ── Machine learning ─────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.immich-machine-learning = {
    image     = "ghcr.io/immich-app/immich-machine-learning:release";
    autoStart = true;

    volumes = [
      "/home/jakub/docker-data/immich-data/model-cache:/cache"
    ];

    extraOptions = [
      "--network=traefik"
      "--network-alias=immich-machine-learning"
    ];
  };

  # ── Server ───────────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.immich-server = {
    image     = "ghcr.io/immich-app/immich-server:release";
    autoStart = true;

    environmentFiles = [ "/home/jakub/secrets/immich.env" ];
    environment = {
      TZ                = "Europe/Warsaw";
      DB_HOSTNAME       = "immich-db";
      DB_USERNAME       = "immich";
      DB_DATABASE_NAME  = "immich";
      REDIS_HOSTNAME    = "immich-redis";
      UPLOAD_LOCATION   = "/usr/src/app/upload";
    };

    volumes = [
      "/home/jakub/docker-data/immich-data/upload:/usr/src/app/upload"
      "/home/jakub/data/photos:/home/jakub/data/photos:ro"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.immich.rule=Host(`immich.home`)"
      "--label=traefik.http.routers.immich.entrypoints=websecure"
      "--label=traefik.http.routers.immich.tls=true"
      "--label=traefik.http.routers.immich.tls.certresolver=step"
      "--label=traefik.http.services.immich.loadbalancer.server.port=2283"
    ];
  };

  # ── Ordering ─────────────────────────────────────────────────────────────────
  systemd.services.docker-immich-db = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };

  systemd.services.docker-immich-redis = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };

  systemd.services.docker-immich-machine-learning = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };

  systemd.services.docker-immich-server = {
    after    = [
      "docker-network-traefik.service"
      "docker-immich-db.service"
      "docker-immich-redis.service"
      "docker-immich-machine-learning.service"
    ];
    requires = [
      "docker-network-traefik.service"
      "docker-immich-db.service"
      "docker-immich-redis.service"
      "docker-immich-machine-learning.service"
    ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      RestartSec   = "30s";
    };
  };
}
