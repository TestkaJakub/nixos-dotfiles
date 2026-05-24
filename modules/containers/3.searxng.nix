{ ... }:

# ───── SearXNG ─────
# Web UI: https://searxng.home
# 
# REMEMBER TO ADD DNS RECORD ON:
# https://pihole.home
{
	# Setting up searxng docker directory
	systemd.tmpfiles.rules = [
		"d /home/jakub/docker-data/searxng-config 0775 jakub jakub -"	
	];

	# Setting up searxng docker container
	virtualisation.oci-containers.containers.searxng = {
		image          = "searxng/searxng";
		autoStart      = true;	

		environment.TZ = "Europe/Warsaw";

		volumes = [
			"/home/jakub/docker-data/searxng-config:/etc/searxng"
		];

		extraOptions = [
			"--network=traefik"
			"--label=traefik.enable=true"
			"--label=traefik.http.routers.searxng.rule=Host(`searxng.home`)"
			"--label=traefik.http.routers.searxng.entrypoints=websecure"
			"--label=traefik.http.routers.searxng.tls=true"
			"--label=traefik.http.routers.searxng.tls.certresolver=step"
			"--label=traefik.http.services.searxng.loadbalancer.server.port=8080"	
		];
	};

	# Ensuring searxng service will start only if traefik network is available
	systemd.services.docker-searxng = {
		after    = [ "docker-network-traefik.service" ];
		requires = [ "docker-network-traefik.service" ];	
	};
}
