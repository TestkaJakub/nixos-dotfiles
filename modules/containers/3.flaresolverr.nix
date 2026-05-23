{ ... }:

# ── FlareSolverr — CloudFlare bypass proxy ─────────────────────────────────────
# Used by Prowlarr to access indexers protected by CloudFlare.
# In Prowlarr: Settings → Indexers → Add FlareSolverr proxy, URL: http://flaresolverr:8191
{
  virtualisation.oci-containers.containers.flaresolverr = {
    image     = "ghcr.io/flaresolverr/flaresolverr:latest";
    autoStart = true;

    environment = {
      LOG_LEVEL = "info";
      TZ        = "Europe/Warsaw";
    };

    extraOptions = [
      "--network=traefik"
    ];
  };

  systemd.services.docker-flaresolverr = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
