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

  programs.steam.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    drivers = [ "amdgpu" ];
    extraPackages = with pkgs; [
      mesa
      amdvlk
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      gtk2
      pipewire
      pulseaudio
      libvdpau
      bzip2
    ];
  };
  nix = { 
    settings.experimental-features = [ "nix-command" "flakes" ];

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  time.timeZone = "Europe/Warsaw";

  system.stateVersion = "25.05"; 
}
