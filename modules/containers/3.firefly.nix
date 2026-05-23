{ pkgs, ... }:

# ───── Firefly III — personal finance manager ─────
# Web UI: https://firefly.home
#
# REMEMBER TO ADD DNS RECORD ON:
# https://pihole.home
#
# ───── Secrets (/home/jakub/secrets/firefly.env) ─────
# APP_KEY=<exactly 32 alphanumeric chars, no special characters>
# DB_PASSWORD=<strong password>
# STATIC_CRON_TOKEN=<exactly 32 alphanumeric chars>
#
# Generate APP_KEY and STATIC_CRON_TOKEN with:
#   head /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32 && echo
#
# ───── Secrets (/home/jakub/secrets/firefly-db.env) ─────
# MYSQL_PASSWORD=<same value as DB_PASSWORD above>
# MYSQL_ROOT_PASSWORD=<another strong password>
# MYSQL_USER=firefly
# MYSQL_DATABASE=firefly
#
# ───── First run ─────
# Visit https://firefly.home and create your admin account.
# Data lives in /home/jakub/docker-data/firefly-db — back this up!
{
	# Setting up firefly docker directory
  	systemd.tmpfiles.rules = [
    	"d /home/jakub/docker-data/firefly-upload 0755 jakub jakub -"
    	"d /home/jakub/docker-data/firefly-db     0755 jakub jakub -"
  	];

  	# Setting up firefly's mariadb docker container
  	virtualisation.oci-containers.containers.firefly-db = {
    	image     = "mariadb:lts";
    	autoStart = true;

    	environmentFiles = [ "/home/jakub/secrets/firefly-db.env" ];

    	volumes = [
      		"/home/jakub/docker-data/firefly-db:/var/lib/mysql"
    	];

    	extraOptions = [
      		"--network=traefik"
      		"--network-alias=firefly-db"
    	];
  	};

  	# Setting up firefly docker container
  	virtualisation.oci-containers.containers.firefly = {
    	image     = "fireflyiii/core:latest";
    	autoStart = true;

    	environmentFiles = [ "/home/jakub/secrets/firefly.env" ];
    	environment = {
      		TZ             = "Europe/Warsaw";
      		APP_URL        = "https://firefly.home";
      		TRUSTED_PROXIES = "**";
      		DB_CONNECTION  = "mysql";
      		DB_HOST        = "firefly-db";
      		DB_PORT        = "3306";
      		DB_DATABASE    = "firefly";
      		DB_USERNAME    = "firefly";
    	};

    	volumes = [
      		"/home/jakub/docker-data/firefly-upload:/var/www/html/storage/upload"
    	];

    	extraOptions = [
      		"--network=traefik"
      		"--label=traefik.enable=true"
      		"--label=traefik.http.routers.firefly.rule=Host(`firefly.home`)"
      		"--label=traefik.http.routers.firefly.entrypoints=websecure"
      		"--label=traefik.http.routers.firefly.tls=true"
      		"--label=traefik.http.routers.firefly.tls.certresolver=step"
      		"--label=traefik.http.services.firefly.loadbalancer.server.port=8080"
    	];
  	};

  	# Setting up fireflie's corn docker container
  	virtualisation.oci-containers.containers.firefly-cron = {
    	image     = "alpine";
    	autoStart = true;
    	dependsOn = [ "firefly" ];

    	environmentFiles = [ "/home/jakub/secrets/firefly.env" ];

    	# Runs at 03:00 daily — hits the cron endpoint using STATIC_CRON_TOKEN from env
    	cmd = [
      		"sh" "-c"
      		''apk add tzdata wget && \
        		(ln -s /usr/share/zoneinfo/Europe/Warsaw /etc/localtime || true) && \
        		echo "0 3 * * * wget -qO- http://firefly:8080/api/v1/cron/$STATIC_CRON_TOKEN" \
          		| crontab - && crond -f -L /dev/stdout''
    	];

    	extraOptions = [
      		"--network=traefik"
    	];
  	};

 	# Ordering
 	systemd.services.docker-firefly-db = {
		after    = [ "docker-network-traefik.service" ];
		requires = [ "docker-network-traefik.service" ];
		serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/rm -f /home/jakub/docker-data/firefly-db/tc.log";
	};

	systemd.services.docker-firefly = {
		after    = [ "docker-network-traefik.service" "docker-firefly-db.service" ];
		requires = [ "docker-network-traefik.service" "docker-firefly-db.service" ];
		serviceConfig = {
	    	ExecStartPre = "${pkgs.coreutils}/bin/sleep 15";
	    	RestartSec = "30s";
	    	StartLimitBurst = 10;
		};
	};

  	systemd.services.docker-firefly-cron = {
    	after    = [ "docker-firefly.service" ];
    	requires = [ "docker-firefly.service" ];
  	};
}
