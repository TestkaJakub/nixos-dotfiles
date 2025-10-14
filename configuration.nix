{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./system/locale.nix
      ./system/graphics.nix
      ./system/boot.nix
      ./services/displayManager.nix
      ./services/networking.nix
      ./services/udev.nix
      ./users/jakub.nix
      ./environment.nix
      ./home-manager.nix
      ./programs/hyprland.nix
    ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [ pkgs.unzip ];

  nix = { 
    settings.experimental-features = [ "nix-command" "flakes" ];

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  time.timeZone = "Europe/Warsaw";

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  users.users.jakub.extraGroups = [ "libvirtd" ];

  networking.firewall = {
    enable = true;
    interfaces."eth0".allowedTCPPorts = [ 5173 ];
  };

  system.stateVersion = "25.05"; 
}
