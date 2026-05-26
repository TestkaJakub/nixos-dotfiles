{ pkgs, config, ... }:

# ── Homelable — homelab infrastructure visualizer ─────────────────────────────
# Builds from source since no pre-built images are published.
# To force a rebuild:
#   docker rmi homelable-backend:local homelable-frontend:local
#   sudo systemctl restart homelable-build.service
#
# ── Secrets (/home/${user}/secrets/homelable.env) ─────────────────────────────
# Web UI: https://homelable.home
let
  user = config.profile.username;
in
{
  systemd.tmpfiles.rules = [
    "d /home/${user}/docker-data/homelable 0755 ${user} ${user} -"
    "d /opt/homelable                       0755 ${user} ${user} -"
  ];

  # ── Build service ────────────────────────────────────────────────────────────
  systemd.services.homelable-build = {
    description = "Build Homelable Docker images from source";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "docker.service" "network-online.target" ];
    requires    = [ "docker.service" ];
    before      = [
      "docker-homelable-backend.service"
      "docker-homelable-frontend.service"
    ];

    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      User            = "root";
      ExecStart = pkgs.writeShellScript "build-homelable" ''
        set -e

        ${pkgs.git}/bin/git config --global --add safe.directory /opt/homelable

        if ! ${pkgs.docker}/bin/docker image inspect homelable-backend:local >/dev/null 2>&1 || \
           ! ${pkgs.docker}/bin/docker image inspect homelable-frontend:local >/dev/null 2>&1; then

          echo "Cloning Homelable..."
          if [ -d /opt/homelable/.git ]; then
            cd /opt/homelable && ${pkgs.git}/bin/git pull
          else
            ${pkgs.git}/bin/git clone https://github.com/Pouzor/homelable /opt/homelable
          fi

          echo "Building backend image..."
          ${pkgs.docker}/bin/docker build \
            -f /opt/homelable/Dockerfile.backend \
            -t homelable-backend:local \
            /opt/homelable

          echo "Building frontend image..."
          ${pkgs.docker}/bin/docker build \
            -f /opt/homelable/Dockerfile.frontend \
            -t homelable-frontend:local \
            /opt/homelable

          echo "Homelable images built successfully."
        else
          echo "Homelable images already exist, skipping build."
        fi
      '';
    };
  };

  # ── Backend ──────────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.homelable-backend = {
    image     = "homelable-backend:local";
    autoStart = true;

    environmentFiles = [ "/home/${user}/secrets/homelable.env" ];
    environment = {
      SQLITE_PATH  = "/app/data/homelab.db";
      CORS_ORIGINS = ''["https://homelable.home"]'';
    };

    volumes = [
      "/home/${user}/docker-data/homelable:/app/data"
    ];

    extraOptions = [
      "--network=traefik"
      "--network-alias=backend"
      "--cap-add=NET_RAW"
    ];
  };

  # ── Frontend ─────────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.homelable-frontend = {
    image     = "homelable-frontend:local";
    autoStart = true;

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.homelable.rule=Host(`homelable.home`)"
      "--label=traefik.http.routers.homelable.entrypoints=websecure"
      "--label=traefik.http.routers.homelable.tls=true"
      "--label=traefik.http.routers.homelable.tls.certresolver=step"
      "--label=traefik.http.services.homelable.loadbalancer.server.port=80"
    ];
  };

  # ── Ordering ─────────────────────────────────────────────────────────────────
  systemd.services.docker-homelable-backend = {
    after    = [ "homelable-build.service" "docker-network-traefik.service" ];
    requires = [ "homelable-build.service" "docker-network-traefik.service" ];
  };

  systemd.services.docker-homelable-frontend = {
    after    = [ "docker-homelable-backend.service" "docker-network-traefik.service" ];
    requires = [ "docker-homelable-backend.service" "docker-network-traefik.service" ];
  };

  systemd.services.docker-traefik = {
    after = [ "docker-homelable-frontend.service" ];
  };
}
