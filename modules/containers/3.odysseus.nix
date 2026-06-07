{ pkgs, config, ... }:

# ── Odysseus AI ────────────────────────────────────────────────────────────────
# Built from source — no pre-built image is published yet.
# Web UI: https://odysseus.home
let
  user = config.profile.username;
in
{
  systemd.tmpfiles.rules = [
    "d /home/${user}/docker-data/odysseus 0755 ${user} ${user} -"
    "d /opt/odysseus                       0755 root root -"
  ];

  systemd.services.odysseus-build = {
    description = "Clone and build Odysseus AI Docker image";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "docker.service" "network-online.target" ];
    requires    = [ "docker.service" ];
    before      = [ "docker-odysseus.service" ];

    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      User            = "root";
      ExecStart = pkgs.writeShellScript "build-odysseus" ''
        set -e
        if ! ${pkgs.docker}/bin/docker image inspect odysseus:local >/dev/null 2>&1; then
          echo "Cloning Odysseus..."
          if [ -d /opt/odysseus/.git ]; then
            cd /opt/odysseus && ${pkgs.git}/bin/git pull
          else
            ${pkgs.git}/bin/git clone https://github.com/pewdiepie-archdaemon/odysseus /opt/odysseus
          fi
          echo "Building Odysseus image..."
          ${pkgs.docker}/bin/docker build -t odysseus:local /opt/odysseus
          echo "Done."
        else
          echo "Odysseus image already exists, skipping build."
        fi
      '';
    };
  };

  virtualisation.oci-containers.containers.odysseus = {
    image     = "odysseus:local";
    autoStart = true;

    environment = {
      TZ           = "Europe/Warsaw";
      APP_BIND     = "0.0.0.0";
      SECURE_COOKIES = "false";
    };

    volumes = [
      "/home/${user}/docker-data/odysseus:/app/data"
    ];

    extraOptions = [
      "--add-host=host.docker.internal:host-gateway"
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
    after    = [ "odysseus-build.service" "docker-network-traefik.service" ];
    requires = [ "odysseus-build.service" "docker-network-traefik.service" ];
  };
}