{ ... }:

# ── Gluetun ────────────────────────────────────────────────────────────────────
# Mullvad WireGuard VPN gateway container.
# qbittorrent.nix routes its traffic through this container's network stack.
# jellyseerr.nix routes outbound HTTP through the built-in SOCKS5 proxy (port 1080).
#
# Secrets: ~/secrets/gluetun.env must contain:
#   WIREGUARD_PRIVATE_KEY=your_key
#   WIREGUARD_ADDRESSES=10.x.x.x/32
{
  virtualisation.oci-containers.containers.gluetun = {
    image     = "qmcgaw/gluetun";
    autoStart = true;

    environmentFiles = [ "/home/jakub/secrets/gluetun.env" ];
    environment = {
      VPN_SERVICE_PROVIDER = "mullvad";
      VPN_TYPE             = "wireguard";
      SERVER_COUNTRIES     = "Chile";
      # Expose SOCKS5 proxy for other containers (e.g. jellyseerr)
      # listening on all interfaces so traefik-network containers can reach it
		HTTPPROXY         = "on";
		HTTPPROXY_ADDRESS = ":8888";
    };

    ports = [
      "6881:6881"
      "6881:6881/udp"
      "8085:8085"
      "8888:8888"
    ];

    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun"
      "--health-cmd=wget -qO- http://127.0.0.1:9999 || exit 1"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=3"
      "--health-start-period=180s"
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.qbittorrent.rule=Host(`qbittorrent.home`)"
      "--label=traefik.http.routers.qbittorrent.entrypoints=websecure"
      "--label=traefik.http.routers.qbittorrent.tls=true"
      "--label=traefik.http.routers.qbittorrent.tls.certresolver=step"
      "--label=traefik.http.services.qbittorrent.loadbalancer.server.port=8085"
    ];
  };
}
