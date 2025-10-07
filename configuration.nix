{ config, lib, pkgs, ... }:
let
  tokyo-night-sddm = pkgs.libsForQt5.callPackage ./tokyo-night-sddm/default.nix { };
in
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
    ];

  home-manager = {
    backupFileExtension = builtins.readFile (pkgs.runCommand "timestamp" {} '' date --utc +%Y-%m-%d_%H-%M-%S > $out'');
    useUserPackages = true;
    useGlobalPkgs = true;
    users.jakub = import ./home.nix;
  };

  nixpkgs.config.allowUnfree = true;

  nix = { 
    settings.experimental-features = [ "nix-command" "flakes" ];

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  time.timeZone = "Europe/Warsaw";

#  programs.firefox.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # environment.systemPackages = with pkgs; [
  #  (writeShellScriptBin "kbm" ''
   #   path="/sys/class/leds/tpacpi::kbd_backlight/brightness"
    #  max_path="/sys/class/leds/tpacpi::kbd_backlight/max_brightness"
#
 #     if [ ! -w "$path" ]; then
  #      echo "Error: cannot write to $path" >&2
      #  exit 1
     # fi

     # cur=$(cat "$path" 2>/dev/null || echo 0)
     # max=$(cat "$max_path" 2>/dev/null || echo 2)

     # if [ "$#" -ge 1 ]; then
       # val="$1"
       # if [ "$val" -gt "$max" ]; then
        #  val="$max"
       # elif [ "$val" -lt 0 ]; then
       #   val=0
      #  fi
     # else
       # if ! [[ "$cur" =~ ^[0-9]+$ ]]; then
        #  cur=0
       # fi
      #  val=$(( (cur + 1) % (max + 1) ))
     # fi

   #   echo "$val" > "$path"
    #'')
  #];

  #environment.variables = {
  #  PF_INFO = "ascii title os host kernel uptime pkgs memory";
  #  PF_SOURCE = "";
  #};

  #environment.sessionVariables.NIXOS_OZONE_WL = "1";

  system.stateVersion = "25.05"; 
}
