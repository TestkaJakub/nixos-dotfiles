{ config, ... }:
let
  user = config.profile.username;
in
{
  systemd.tmpfiles.rules = [
    "d /home/${user}/docker-data/searxng-config 0775 ${user} ${user} -"
  ];

  virtualisation.oci-containers.containers.searxng = {
    image     = "searxng/searxng";
    autoStart = true;
    environment.TZ = "Europe/Warsaw";
    volumes = [ "/home/${user}/docker-data/searxng-config:/etc/searxng" ];
    ports   = [ "8080:8080" ];
  };

  systemd.services.docker-searxng = {
    after    = [ "docker.service" ];
    requires = [ "docker.service" ];
  };
}