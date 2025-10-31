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

  services.x11vnc = {
    enable = true;
    display = ":0";
    password = "mysecret";  # Or use passwordFile for more security
  };
  
  services.blueman.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    group = user;
    extraGroups = [ "wheel" "dialout" "libvirtd" ];
    shell = pkgs.bashInteractive;
  };

  users.groups.${user} = {};
    programs.mango.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="tpacpi::kbd_backlight", \
      RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/class/leds/tpacpi::kbd_backlight/brightness"
  '';

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
}
