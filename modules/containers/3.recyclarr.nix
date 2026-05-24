{ ... }:

# ── Recyclarr — TRaSH Guides sync for Radarr/Sonarr ──────────────────────────
# Syncs quality profiles and custom formats from TRaSH Guides.
# Config: /home/jakub/docker-data/recyclarr-config/recyclarr.yml
# Remember to fill in your Radarr/Sonarr API keys in the config!
#
# To run manually:
#   docker exec recyclarr recyclarr sync
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/recyclarr-config 0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.recyclarr = {
    image     = "ghcr.io/recyclarr/recyclarr:latest";
    autoStart = true;

    environment = {
      TZ = "Europe/Warsaw";
      RECYCLARR_CREATE_CONFIG = "false";
    };

    volumes = [
      "/home/jakub/docker-data/recyclarr-config:/config"
    ];

    extraOptions = [
      "--network=traefik"
    ];
  };

  systemd.services.docker-recyclarr = {
    after    = [ "docker-network-traefik.service" "docker-radarr.service" "docker-sonarr.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
