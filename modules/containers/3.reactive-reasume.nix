{ pkgs, ... }:

# ── Reactive Resume — self-hosted resume builder ───────────────────────────────
# Web UI: https://resume.home
#
# Bootstrap secrets (run once):
#   mkdir -p /home/jakub/secrets
#   echo 'AUTH_SECRET='$(openssl rand -hex 32) >> /home/jakub/secrets/reactive-resume.env
#   echo 'POSTGRES_PASSWORD=changeme'           >> /home/jakub/secrets/reactive-resume.env
#   chmod 600 /home/jakub/secrets/reactive-resume.env
#
# To add DNS record:
#   echo "192.168.0.252 resume.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/reactive-resume-db   0755 jakub jakub -"
    "d /home/jakub/docker-data/reactive-resume-data 0755 jakub jakub -"
  ];

  # ── PostgreSQL ───────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.reactive-resume-db = {
    image     = "postgres:latest";
    autoStart = true;

    environmentFiles = [ "/home/jakub/secrets/reactive-resume.env" ];
    environment = {
      POSTGRES_DB   = "postgres";
      POSTGRES_USER = "postgres";
    };

    volumes = [
      "/home/jakub/docker-data/reactive-resume-db:/var/lib/postgresql"
    ];

    extraOptions = [
      "--network=traefik"
      "--network-alias=reactive-resume-db"
      "--health-cmd=pg_isready -U postgres -d postgres"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=10"
    ];
  };

  # ── Printer (headless Chromium for PDF export) ───────────────────────────────
  virtualisation.oci-containers.containers.reactive-resume-printer = {
    image     = "ghcr.io/browserless/chromium:latest";
    autoStart = true;

    environment = {
      HEALTH      = "true";
      CONCURRENT  = "10";
      QUEUED      = "5";
    };

    extraOptions = [
      "--network=traefik"
      "--network-alias=reactive-resume-printer"
      "--health-cmd=curl -f http://localhost:3000/pressure"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=10"
    ];
  };

  # ── App ───────────────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.reactive-resume = {
    image     = "amruthpillai/reactive-resume:latest";
    autoStart = true;

    environmentFiles = [ "/home/jakub/secrets/reactive-resume.env" ];
    environment = {
      TZ                = "Europe/Warsaw";
      APP_URL           = "https://resume.home";
      PRINTER_APP_URL   = "http://reactive-resume:3000";
      PRINTER_ENDPOINT  = "ws://reactive-resume-printer:3000";
      FLAG_DISABLE_SIGNUPS = "true";  # set to false for first-time account creation
    };

    volumes = [
      "/home/jakub/docker-data/reactive-resume-data:/app/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--add-host=host.docker.internal:host-gateway"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.reactive-resume.rule=Host(`resume.home`)"
      "--label=traefik.http.routers.reactive-resume.entrypoints=websecure"
      "--label=traefik.http.routers.reactive-resume.tls=true"
      "--label=traefik.http.routers.reactive-resume.tls.certresolver=step"
      "--label=traefik.http.services.reactive-resume.loadbalancer.server.port=3000"
    ];
  };

  # ── Ordering ─────────────────────────────────────────────────────────────────
  systemd.services.docker-reactive-resume-db = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };

  systemd.services.docker-reactive-resume-printer = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };

  systemd.services.docker-reactive-resume = {
    after    = [ "docker-network-traefik.service" "docker-reactive-resume-db.service" "docker-reactive-resume-printer.service" ];
    requires = [ "docker-network-traefik.service" "docker-reactive-resume-db.service" "docker-reactive-resume-printer.service" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      RestartSec   = "30s";
    };
  };
}
