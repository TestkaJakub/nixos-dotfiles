{ config, lib, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.jakub = import ./home.nix;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  nix = { 
    settings.experimental-features = [ "nix-command" "flakes" ];

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Warsaw";

  services = {
  #  xserver = {
  #    enable = true;
  #    windowManager.qtile.enable = true;
  #    extraConfig = ''
  #      Section "Monitor"
  #      Identifier "Virtual-1"
  #      Option "PreferredMode" "1920x1080"
  #      EndSection
  #    '';
  #    displayManager.sessionCommands = ''
  #      xwallpaper --zoom ~/Wallpapers/toradora.png
  #      xset r rate 200 35 &
  #    '';
  #  };

    picom = {
      enable = true;
      backend = "glx";
      fade = true;
    };
  };

  users.users.jakub = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dialout" ]; 
    packages = with pkgs; [
      tree
    ];
  };

  programs.firefox.enable = true;
  programs.hyprland.enable = true;
  programs.hyprland.packages = hyprland.packages."25.05".hyprland;
  #programs.sway.enable = true;

  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    alacritty
    btop
    #xwallpaper
    pcmanfm
    rofi
    pfetch-rs
    kitty
  ];

  environment.variables = {
    PF_INFO = "ascii title os host kernel uptime pkgs memory";
    PF_SOURCE = "";
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];
  system.stateVersion = "25.05"; 
}
