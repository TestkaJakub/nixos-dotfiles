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
  enableOnBoot = false; # disable rootful daemon

  rootless = {
    enable = true;
    setSocketVariable = true;
  };
};

# Automatically start rootless docker for your user
systemd.user.services.docker.wantedBy = [ "default.target" ];

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

      volumes = [
        "/home/jakub/docker-data/vikunja-db:/var/lib/postgresql/data"
      ];

      autoStart = true;
    };

    vikunja = {
      image = "vikunja/vikunja:latest";

      ports = [ "3456:3456" ];

      environment = {
        VIKUNJA_SERVICE_JWTSECRET = "change-me-later";
        VIKUNJA_DATABASE_HOST = "vikunja-db";
        VIKUNJA_DATABASE_PASSWORD = ""; # loaded from env file below
        VIKUNJA_DATABASE_USER = "vikunja";
        VIKUNJA_DATABASE_DATABASE = "vikunja";
        VIKUNJA_DATABASE_TYPE = "postgres";
      };

      dependsOn = [ "vikunja-db" ];

      environmentFiles = [
        "/home/jakub/secrets/vikunja-db.env"
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
    extraGroups = [ "wheel" "dialout" "libvirtd" "adbusers" "scanner" "lp" ];
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
