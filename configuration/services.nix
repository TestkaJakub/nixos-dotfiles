{ pkgs, lib, config, user, ... }:

{
  services.displayManager = {
    enable = true;
    sddm = {
      enable = true;
      wayland.enable = true;
    };
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
    extraGroups = [ "wheel" "dialout" "libvirtd" "adbusers" ];
    shell = pkgs.bashInteractive;
  };

  users.groups.${user} = {};
    programs.mango.enable = true;

# Force the Wayland portal service to start
# Force wlroots portal to start even if WAYLAND_DISPLAY is unset
  systemd.user.services."xdg-desktop-portal-wlr" = {
    enable = true;
    wantedBy = [ "default.target" ];

    unitConfig = {
      # Normally "ConditionEnvironment=WAYLAND_DISPLAY" — remove it
      ConditionEnvironment = lib.mkForce [ ];
    };

    serviceConfig = {
      Environment = "WAYLAND_DISPLAY=wayland-1";
    };
  };

    #systemd.user.services."xdg-desktop-portal-wlr".serviceConfig.ConditionEnvironment =
    #lib.mkForce [ ];

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
}
