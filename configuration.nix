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

  environment.variables = {
    STEAM_RUNTIME = "0";
    PRESSURE_VESSEL = "0";
    STEAM_NO_OVERLAY = "1";
  };

  programs.steam = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    (pkgs.runCommand "bzip2-compat-32" { buildInputs = [ pkgsi686Linux.bzip2 ]; } ''
      mkdir -p $out/lib
      target=$(ls ${pkgsi686Linux.bzip2.out}/lib/libbz2.so.1* | head -n1)
      ln -s "$target" "$out/lib/libbz2.so.1.0"
    '')
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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

      (pkgs.runCommand "bzip2-compat-32" { buildInputs = [ pkgsi686Linux.bzip2 ]; } ''
        mkdir -p $out/lib
        target=$(ls ${pkgsi686Linux.bzip2.out}/lib/libbz2.so.1* | head -n1)
        ln -s $target $out/lib/libbz2.so.1.0
      '') 
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
