{ config, ... }:

# ── SearXNG (desktop) ─────────────────────────────────────────────────────────
# Odysseus → http://searxng:8080 over the `ai` network (see 4.ollama-rcom.nix)
# Desktop  → http://127.0.0.1:8080
let
  user = config.profile.username;
in
{
  systemd.tmpfiles.rules = [
    "d /home/${user}/docker-data/searxng-config 0775 ${user} ${user} -"
  ];

  virtualisation.oci-containers.containers.searxng = {
    image     = "searxng/searxng";
    autoStart = true;
    environment.TZ = "Europe/Warsaw";
    volumes = [ "/home/${user}/docker-data/searxng-config:/etc/searxng" ];
    ports   = [ "127.0.0.1:8080:8080" ];
    extraOptions = [
      "--network=ai"
      "--network-alias=searxng"
    ];
  };

  systemd.services.docker-searxng = {
    after    = [ "docker.service" "docker-network-ai.service" ];
    requires = [ "docker.service" "docker-network-ai.service" ];
  };
}