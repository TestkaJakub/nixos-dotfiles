{ config, lib, pkgs, ... }:
let
  tokyo-night-sddm = pkgs.libsForQt5.callPackage ./tokyo-night-sddm/default.nix { };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  home-manager = {
    backupFileExtension = builtins.readFile (pkgs.runCommand "timestamp" {} '' date --utc +%Y-%m-%d_%H-%M-%S > $out'');
    useUserPackages = true;
    useGlobalPkgs = true;
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
    displayManager = {
      enable = true;
      sddm = {
        enable = true;
        theme = "tokyo-night-sddm";
	wayland = {
	  enable = true;
	};
      };
    };
    picom = {
      enable = true;
      backend = "glx";
      fade = true;
    };
    udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="tpacpi::kbd_backlight", \
      RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/class/leds/tpacpi::kbd_backlight/brightness"
  '';
  };

  users.users.jakub = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dialout" ]; 
    packages = with pkgs; [
      tree
    ];
  };

  programs.firefox.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  
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
    hyprlock
    tokyo-night-sddm
    git
    (writeShellScriptBin "kbm" ''
    echo "$1" > /sys/class/leds/tpacpi::kbd_backlight/brightness
    '')
  ];

  environment.variables = {
    PF_INFO = "ascii title os host kernel uptime pkgs memory";
    PF_SOURCE = "";
  };

  #environment.sessionVariables.NIXOS_OZONE_WL = "1";

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

#  systemd.services."set-kbd-backlight" = {
#    description = "Set ThinkPad keyboard backlight";
#    wantedBy = [ "multi-user.target" ];
#    after = [ "sysinit.target" ];
#    serviceConfig = {
#      Type = "oneshot";
#      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 2 > /sys/class/leds/tpacpi::kbd_backlight/brightness'";
#    };
#  };

  system.stateVersion = "25.05"; 
}
