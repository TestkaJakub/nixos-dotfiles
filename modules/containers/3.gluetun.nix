{ ... }:

# ── Gluetun ────────────────────────────────────────────────────────────────────
# Mullvad WireGuard VPN gateway container.
#
# Consumers (all over the `traefik` Docker network, nothing published on host):
#   qbittorrent  shares this container's network stack (--network=container:gluetun),
#                WebUI reached by Traefik at gluetun:8085 → https://qbittorrent.home
#   jellyseerr   outbound HTTP(S) via the built-in HTTP proxy at gluetun:8888
#
# No `ports` on purpose: Docker-published ports bypass the NixOS firewall and
# would expose the proxy and the WebUI to the whole LAN. Mullvad has no port
# forwarding, so publishing the torrent port wouldn't accept inbound peers anyway.
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

      # HTTP proxy for other containers on the traefik network (jellyseerr).
      HTTPPROXY         = "on";
      HTTPPROXY_ADDRESS = ":8888";
    };

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