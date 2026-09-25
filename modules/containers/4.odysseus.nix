{ pkgs, config, ... }:

# ── Odysseus AI (desktop) ──────────────────────────────────────────────────────
# Runs only on the desktop, next to the ROCm Ollama container.
#
# Access paths — nothing is published to the LAN:
#   desktop         → http://localhost:7000
#   tailnet devices → http://desktop:7000 via `tailscale serve` (below)
#
# Backends over the `ai` Docker network (created in 4.ollama-rcom.nix):
#   Ollama  → http://ollama:11434
#   SearXNG → http://searxng:8080
let
  user      = config.profile.username;
  docker    = "${pkgs.docker}/bin/docker";
  git       = "${pkgs.git}/bin/git";
  tailscale = "${config.services.tailscale.package}/bin/tailscale";
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
    };
    script = ''
      set -e
      if ! ${docker} image inspect odysseus:local >/dev/null 2>&1; then
        echo "Cloning Odysseus..."
        if [ -d /opt/odysseus/.git ]; then
          cd /opt/odysseus && ${git} pull
        else
          ${git} clone https://github.com/pewdiepie-archdaemon/odysseus /opt/odysseus
        fi
        echo "Building Odysseus image..."
        ${docker} build -t odysseus:local /opt/odysseus
      else
        echo "Odysseus image already exists, skipping build."
      fi
    '';
  };

  virtualisation.oci-containers.containers.odysseus = {
    image     = "odysseus:local";
    autoStart = true;

    environment = {
      TZ             = "Europe/Warsaw";
      APP_BIND       = "0.0.0.0";   # inside the container; exposure is controlled by `ports`
      SECURE_COOKIES = "false";     # served over plain HTTP (tailnet traffic is WireGuard-encrypted)
    };

    volumes = [ "/home/${user}/docker-data/odysseus:/app/data" ];
    ports   = [ "127.0.0.1:7000:7000" ];

    extraOptions = [ "--network=ai" ];
  };

  systemd.services.docker-odysseus = {
    after    = [ "odysseus-build.service" "docker-network-ai.service" ];
    requires = [ "odysseus-build.service" "docker-network-ai.service" ];
  };

  # ── Expose on the tailnet only ──────────────────────────────────────────────
  systemd.services.tailscale-serve-odysseus = {
    description = "Expose Odysseus on the tailnet via tailscale serve";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "tailscaled.service" "docker-odysseus.service" ];
    wants       = [ "tailscaled.service" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for _ in $(seq 30); do
        ${tailscale} status >/dev/null 2>&1 && break
        sleep 2
      done
      ${tailscale} serve --bg --tcp 7000 tcp://127.0.0.1:7000
    '';
  };
}