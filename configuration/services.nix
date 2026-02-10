{ pkgs, lib, config, user, ... }:

{
  services.displayManager = {
    enable = true;
    sddm = {
      enable = true;
      wayland.enable = true;
    };
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
    extraBackends = [ pkgs.epson-escpr2 ];
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
