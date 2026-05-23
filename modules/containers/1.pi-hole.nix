{ config, ... }:

# ── Pi-hole — DNS resolver for *.home ─────────────────────────────────────────
# Server only — requires static IP 192.168.0.252 to be a reliable DNS target.
#
# ── Adding a new service domain ───────────────────────────────────────────────
# Pi-hole web UI → Local DNS → DNS Records:
#   Domain: myservice.home   IP: 192.168.0.252
#
# Or via dnsmasq config file:
#   echo "address=/myservice.home/192.168.0.252" \
#     >> /home/${user}/docker-data/pihole/dnsmasq/02-custom.conf
#   docker restart pihole
#
# ── Secrets (/home/${user}/secrets/pihole.env) ────────────────────────────────
#   FTLCONF_webserver_api_password=your_strong_password
#
# ── Web UI ────────────────────────────────────────────────────────────────────
# https://pihole.home (via Traefik)
# http://192.168.0.252:8053/admin (direct fallback)
let
  user = config.profile.username;
in
{
  systemd.tmpfiles.rules = [
    "d /home/${user}/docker-data/pihole         0755 root root -"
    "d /home/${user}/docker-data/pihole/pihole  0755 root root -"
    "d /home/${user}/docker-data/pihole/dnsmasq 0755 root root -"
  ];

  virtualisation.oci-containers.containers.pihole = {
    image     = "pihole/pihole:latest";
    autoStart = true;

    environmentFiles = [ "/home/${user}/secrets/pihole.env" ];
    environment = {
      TZ                        = "Europe/Warsaw";
      PIHOLE_DNS_1              = "1.1.1.1";
      PIHOLE_DNS_2              = "1.0.0.1";
      BLOCKING_ENABLED          = "false";
      VIRTUAL_HOST              = "pihole.home";
      CORS_HOSTS                = "pihole.home";
      FTLCONF_webserver_port    = "8053o";
      FTLCONF_dns_listeningMode = "ALL";
    };

    volumes = [
      "/home/${user}/docker-data/pihole/pihole:/etc/pihole"
      "/home/${user}/docker-data/pihole/dnsmasq:/etc/dnsmasq.d"
    ];

    extraOptions = [
      "--network=host"
      "--cap-add=NET_ADMIN"
    ];
  };

  systemd.services.docker-pihole = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}