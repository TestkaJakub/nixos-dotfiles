{ pkgs, lib, config, user, ... }:

{
  services.displayManager = {
    enable = true;
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

virtualisation.docker = {
    enable = true;
    daemon.settings = {
    userland-proxy = false;
    experimental = true;
  };
};

virtualisation.oci-containers = {
  backend = "docker";
  containers = {

  	gluetun = {
      image = "qmcgaw/gluetun";
      autoStart = true;
    
	  environmentFiles = [ "/home/jakub/secrets/gluetun.env" ];

	  environment = {
	    VPN_SERVICE_PROVIDER = "mullvad";
	    VPN_TYPE = "wireguard";
	    SERVER_COUNTRIES = "Poland";

	    VPN_PORT_FORWARDING = "on";
	    VPN_PORT_FORWARDING_PROVIDER = "mullvad";
	    VPN_PORT_FORWARDING_UP_COMMAND =
	      "/bin/sh -c 'wget -O- --retry-connrefused --post-data \"json={\\\"listen_port\\\":{{PORTS}}}\" http://127.0.0.1:8085/api/v2/app/setPreferences 2>&1'";
	  };
    
      ports = [
        "6881:6881"
        "6881:6881/udp"
        "8085:8085"
      ];
    
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
    
        "--health-cmd=ping -c 1 1.1.1.1"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=60s"
      ];
    };

    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      autoStart = true;

      dependsOn = [ "gluetun" ];

      environment = {
        WEBUI_PORT = "8085";
        PUID = "1000";
        PGID = "1000";
        TZ = "Europe/Warsaw";
      };

      volumes = [
        "/home/jakub/docker-data/qbittorrent-config:/config"
        "/home/jakub/downloads:/data"
      ];

      extraOptions = [
        "--network=container:gluetun"
      ];
    };

    vikunja-db = {
      image = "postgres:16";
      environmentFiles = [
        "/home/jakub/secrets/vikunja-db.env"
      ];

      environment = {
        POSTGRES_USER = "vikunja";
        POSTGRES_DB = "vikunja";
      };
      extraOptions = [
		"--network=host"
	  ];
      volumes = [
        "/home/jakub/docker-data/vikunja-db:/var/lib/postgresql/data"
      ];

      autoStart = true;
    };
	vikunja = {
	  image = "vikunja/vikunja:latest";

	  environment = {
	    VIKUNJA_DATABASE_HOST = "127.0.0.1";
	    VIKUNJA_DATABASE_USER = "vikunja";
	    VIKUNJA_DATABASE_DATABASE = "vikunja";
	    VIKUNJA_DATABASE_TYPE = "postgres";
	    VIKUNJA_SERVICE_PUBLICURL = "http://localhost:3456";
	  };

	  dependsOn = [ "vikunja-db" ];

	  environmentFiles = [
	    "/home/jakub/secrets/vikunja-db.env"
	  ];
	  volumes = [
	    "/home/jakub/docker-data/vikunja-files:/app/vikunja/files"
	  ];

	  extraOptions = [
	  "--network=host"
	    "--user=0"
	  ];
	  autoStart = true;
	};
    
  };
};

  services.resolved.enable = true;

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.epson-escpr ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };



  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };
  
  services.blueman.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    group = user;
    extraGroups = [ "wheel" "dialout" "libvirtd" "adbusers" "scanner" "lp" "docker" ];
    shell = pkgs.bashInteractive;
  };

  users.groups.${user} = {};
    programs.mango.enable = true;

  systemd.user.services.xdg-desktop-portal-wlr = {
    overrideStrategy = "asDropin"; # Ensures we merge with upstream instead of replacing
    unitConfig = {
      # Use lib.mkForce to override the upstream condition
      ConditionEnvironment = lib.mkForce ""; 
    };
  };

    #systemd.user.services."xdg-desktop-portal-wlr".serviceConfig.ConditionEnvironment =
    #lib.mkForce [ ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
}
