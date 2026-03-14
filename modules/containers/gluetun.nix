{ ... }:

# ── Gluetun ────────────────────────────────────────────────────────────────────
# Mullvad WireGuard VPN gateway container.
# qbittorrent.nix routes its traffic through this container's network stack
# via --network=container:gluetun.
#
# Secrets: /home/jakub/secrets/gluetun.env must contain WIREGUARD_PRIVATE_KEY
# and any other secrets not listed here.
{
  virtualisation.oci-containers.containers.gluetun = {
    image     = "qmcgaw/gluetun";
    autoStart = true;

    environmentFiles = [ "/home/jakub/secrets/gluetun.env" ];
    environment = {
      VPN_SERVICE_PROVIDER = "mullvad";
      VPN_TYPE             = "wireguard";
      SERVER_COUNTRIES     = "Chile";
      SERVER_CITIES        = "Santiago";
    };

    ports = [
      "6881:6881"
      "6881:6881/udp"
      "8085:8085"
    ];

    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun"
      # Use exec-form JSON array for health-cmd so the arguments are passed
      # directly to the kernel without shell parsing — avoids quoting issues.
      ''--health-cmd=["ping","-c","1","1.1.1.1"]''
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=3"
      "--health-start-period=60s"
    ];
  };
}
