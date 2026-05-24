{ ... }:

# ── Byparr ─────────────────────────────────────────────────────────────────────
# FlareSolverr-compatible Cloudflare bypass proxy.
# In Prowlarr: Settings → Indexers → Add FlareSolverr proxy, URL: http://byparr:8191
{
  virtualisation.oci-containers.containers.byparr = {
    image     = "ghcr.io/thephaseless/byparr:latest";
    autoStart = true;

    environment = {
      HOST = "0.0.0.0";
      PORT = "8191";
    };

    extraOptions = [
      "--network=traefik"
    ];
  };

  systemd.services.docker-byparr = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
