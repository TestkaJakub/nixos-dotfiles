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

systemd.services.create-vikunja-network = {
  description = "Create vikunja docker network";
  after = [ "docker.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.docker}/bin/docker network inspect vikunja-net >/dev/null 2>&1 || ${pkgs.docker}/bin/docker network create vikunja-net'";
  };
};

virtualisation.oci-containers = {
  backend = "docker";
  containers = {

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
  "--network=vikunja-net"
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
