{ ... }:

# ───── Bazarr ─────
# Automatically downloads subtitles for Radarr and Sonarr content.
# Web UI: https://bazarr.home
# 
# REMEMBER TO ADD DNS RECORD ON:
# https://pihole.home
{
	# Setting up bazzar docker directory
  	systemd.tmpfiles.rules = [
    	"d /home/jakub/docker-data/bazarr-config 0755 jakub jakub -"
  	];

	# Setting up bazzar docker container
  	virtualisation.oci-containers.containers.bazarr = {
    	image     = "lscr.io/linuxserver/bazarr:latest";
    	autoStart = true;

    	environment = {
      		PUID = "1000";
      		PGID = "1000";
      		TZ   = "Europe/Warsaw";
    	};

    	volumes = [
      		"/home/jakub/docker-data/bazarr-config:/config"
      		"/home/jakub/data:/data"
    	];

    	extraOptions = [
      		"--network=traefik"
      		"--label=traefik.enable=true"
      		"--label=traefik.http.routers.bazarr.rule=Host(`bazarr.home`)"
      		"--label=traefik.http.routers.bazarr.entrypoints=websecure"
      		"--label=traefik.http.routers.bazarr.tls=true"
      		"--label=traefik.http.routers.bazarr.tls.certresolver=step"
      		"--label=traefik.http.services.bazarr.loadbalancer.server.port=6767"
    	];
  	};
  	
	# Ensuring bazzar service will start only if traefik network is available
  	systemd.services.docker-bazarr = {
    	after    = [ "docker-network-traefik.service" ];
    	requires = [ "docker-network-traefik.service" ];
  	};
}
