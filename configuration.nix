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

  i18n = {
    defaultLocale = "pl_PL.UTF-8";

    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "pl_PL.UTF-8/UTF-8"
    ];
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
      path="/sys/class/leds/tpacpi::kbd_backlight/brightness"
      max_path="/sys/class/leds/tpacpi::kbd_backlight/max_brightness"

      if [ ! -w "$path" ]; then
        echo "Error: cannot write to $path" >&2
        exit 1
      fi

      cur=$(cat "$path" 2>/dev/null || echo 0)
      max=$(cat "$max_path" 2>/dev/null || echo 2)

      if [ "$#" -ge 1 ]; then
        val="$1"
        if [ "$val" -gt "$max" ]; then
          val="$max"
        elif [ "$val" -lt 0 ]; then
          val=0
        fi
      else
        if ! [[ "$cur" =~ ^[0-9]+$ ]]; then
          cur=0
        fi
        val=$(( (cur + 1) % (max + 1) ))
      fi

      echo "$val" > "$path"
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
