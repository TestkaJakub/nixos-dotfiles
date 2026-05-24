{ ... }:

# ── Jellyseerr — media request manager ────────────────────────────────────────
# Web UI: https://jellyseerr.home
# Connects to Jellyfin for auth, Radarr for movies, Sonarr for TV.
#
# Outbound traffic (TMDB API calls etc.) is routed through Gluetun's built-in
# SOCKS5 proxy to work around ISP blocks on the movie database.
# Gluetun exposes SOCKS5 on port 1080 — enabled via SOCKS5_ADDRESS below.
#
# To add DNS record:
#   echo "192.168.0.252 jellyseerr.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
#
# ── First-time setup (in the web UI) ──────────────────────────────────────────
# 1. Sign in with your Jellyfin account
# 2. Settings → Radarr → Add Radarr:
#      hostname: radarr   port: 7878   API key: (from Radarr UI)
# 3. Settings → Sonarr → Add Sonarr:
#      hostname: sonarr   port: 8989   API key: (from Sonarr UI)
# 4. Settings → Jellyfin:
#      hostname: jellyfin  port: 8096
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/jellyseerr-config 0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.jellyseerr = {
    image     = "fallenbagel/jellyseerr:latest";
    autoStart = true;

    environment = {
      LOG_LEVEL  = "info";
      TZ         = "Europe/Warsaw";
      # Route outbound HTTP/HTTPS through Gluetun's SOCKS5 proxy.
      # "gluetun" resolves inside the traefik Docker network.
		HTTP_PROXY  = "http://gluetun:8888";
		HTTPS_PROXY = "http://gluetun:8888";
      # Don't proxy internal requests to your own services
      NO_PROXY    = "localhost,127.0.0.1,radarr,sonarr,jellyfin,prowlarr,192.168.0.0/24,*.home";
    };

    volumes = [
      "/home/jakub/docker-data/jellyseerr-config:/app/config"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.jellyseerr.rule=Host(`jellyseerr.home`)"
      "--label=traefik.http.routers.jellyseerr.entrypoints=websecure"
      "--label=traefik.http.routers.jellyseerr.tls=true"
      "--label=traefik.http.routers.jellyseerr.tls.certresolver=step"
      "--label=traefik.http.services.jellyseerr.loadbalancer.server.port=5055"
    ];
  };

  systemd.services.docker-jellyseerr = {
    after    = [ "docker-network-traefik.service" "docker-gluetun.service" ];
    requires = [ "docker-network-traefik.service" "docker-gluetun.service" ];
  };
}
