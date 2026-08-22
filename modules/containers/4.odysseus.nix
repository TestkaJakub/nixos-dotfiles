{ pkgs, config, ... }:

# ── Odysseus AI (desktop, standalone) ──────────────────────────────────────────
# Desktop runs Odysseus without the Traefik/step-ca stack that server +
# workstation use (containers/3.odysseus.nix). The container publishes its port
# directly, so you reach it at http://localhost:7000. Talks to the local Ollama
# service on the host via host.docker.internal:11434.
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
      TZ             = "Europe/Warsaw";
      APP_BIND       = "0.0.0.0";
      SECURE_COOKIES = "false";
    };

    volumes = [ "/home/${user}/docker-data/odysseus:/app/data" ];
    ports   = [ "7000:7000" ];

    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
  };

  systemd.services.docker-odysseus = {
    after    = [ "odysseus-build.service" ];
    requires = [ "odysseus-build.service" ];
    models = "/home/jakub/data/ollama-models";
  };
}