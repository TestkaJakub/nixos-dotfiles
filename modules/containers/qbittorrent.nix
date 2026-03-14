{ ... }:

# ── qBittorrent ────────────────────────────────────────────────────────────────
# Torrent client. All traffic is routed through the gluetun VPN container
# via --network=container:gluetun. It therefore has no exposed ports of its
# own — it inherits gluetun's port 8085 for the web UI.
#
# Uses the libtorrentv1 tag (static build against libtorrent v1) rather than
# :latest to avoid silent breaking changes on rebuild.
{
  virtualisation.oci-containers.containers.qbittorrent = {
    image     = "lscr.io/linuxserver/qbittorrent:libtorrentv1";
    autoStart = true;
    dependsOn = [ "gluetun" ];

    environment = {
      WEBUI_PORT = "8085";
      PUID       = "1000";
      PGID       = "1000";
      TZ         = "Europe/Warsaw";
    };

    volumes = [
      "/home/jakub/docker-data/qbittorrent-config:/config"
      "/home/jakub/downloads:/downloads"
    ];

    extraOptions = [ "--network=container:gluetun" ];
  };
}
