{ ... }:

# ── qBittorrent ────────────────────────────────────────────────────────────────
# All traffic routed through gluetun VPN container.
# Downloads go to /home/jakub/data/downloads on the LVM storage disk.
# Web UI accessible at https://qbittorrent.home via Traefik.
#
# Traefik labels are on gluetun since qBittorrent shares its network stack.
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/qbittorrent-config 0755 jakub jakub -"
    "d /home/jakub/data/downloads                         0775 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.qbittorrent = {
    image     = "lscr.io/linuxserver/qbittorrent:libtorrentv1";
    autoStart = true;
    dependsOn = [ "gluetun" ];

	environment = {
	  WEBUI_PORT    = "8085";
	  WEBUI_ADDRESS = "0.0.0.0";
	  PUID          = "1000";
	  PGID          = "1000";
	  TZ            = "Europe/Warsaw";
	};

    volumes = [
      "/home/jakub/docker-data/qbittorrent-config:/config"
      "/home/jakub/data/downloads:/downloads"
    ];

    extraOptions = [ "--network=container:gluetun" ];
  };
}
