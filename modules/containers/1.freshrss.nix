{ config, ... }:

# ── FreshRSS — self-hosted RSS aggregator ─────────────────────────────────────
# Web UI: https://freshrss.home
#
# To add DNS record:
#   echo "192.168.0.252 freshrss.home" >> /home/jakub/docker-data/pihole/pihole/custom.list
#   docker exec pihole pihole reloaddns
#
# Default credentials set via environment:
#   user: admin  password: see FRESHRSS_DEFAULT_USER_PASS below
#
# Android client: use Feeder (F-Droid) with the Google Reader API:
#   Server URL: https://freshrss.home/api/greader.php
#   Username:   admin
#   Password:   your password
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/freshrss-config 0755 jakub jakub -"
    "d /home/jakub/docker-data/freshrss-data   0755 jakub jakub -"
  ];

  virtualisation.oci-containers.containers.freshrss = {
    image     = "freshrss/freshrss:latest";
    autoStart = true;

    environment = {
      TZ                          = "Europe/Warsaw";
      CRON_MIN                    = "*/15";
      FRESHRSS_ENV                = "production";
      FRESHRSS_DEFAULT_USER       = "admin";
    };

    environmentFiles = [ "/home/jakub/secrets/freshrss.env" ];

    volumes = [
      "/home/jakub/docker-data/freshrss-data:/var/www/FreshRSS/data"
      "/home/jakub/docker-data/freshrss-config:/var/www/FreshRSS/extensions"
    ];

    extraOptions = [
      "--network=traefik"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.freshrss.rule=Host(`freshrss.home`)"
      "--label=traefik.http.routers.freshrss.entrypoints=websecure"
      "--label=traefik.http.routers.freshrss.tls=true"
      "--label=traefik.http.routers.freshrss.tls.certresolver=step"
      "--label=traefik.http.services.freshrss.loadbalancer.server.port=80"
    ];
  };

  systemd.services.docker-freshrss = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}