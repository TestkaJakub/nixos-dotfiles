{ pkgs, lib, config, user, ... }:

let
  tokyo-night-sddm =
    pkgs.libsForQt5.callPackage ../tokyo-night-sddm/default.nix { };
in
{
  services.displayManager = {
    enable = true;
    sddm = {
      enable = true;
      theme = "tokyo-night-sddm";
      wayland.enable = true;
    };
  };


  users.users.jakub = {
    isNormalUser = true;
    group = user;
    extraGroups = [ "wheel" "dialout" "libvirtd" ];
    shell = pkgs.bashInteractive;
  };

  users.groups.jakub = {};
    programs.mango.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="tpacpi::kbd_backlight", \
      RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/class/leds/tpacpi::kbd_backlight/brightness"
  '';

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  environment.systemPackages = [ tokyo-night-sddm ];
}
