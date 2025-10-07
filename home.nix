{ config, pkgs, ... }:
{
  home = {
    username = "jakub";
    stateVersion = "25.05";
    sessionVariables.NIXOS_OZONE_WL = "1";
    packages = with pkgs; [
      bat
      btop
      git
      arduino-core
      arduino-cli
      fastfetch
      hyprpaper
      git
      hyprlock
      wget
      pfetch-rs
      kitty
      fuzzel
      obsidian
      hyprsunset
      scrcpy
      wl-clipboard
    ];
  };

  imports = [
    ./bash.nix
    ./programs/alacritty.nix
    ./programs/fuzzel.nix
    ./programs/neovim.nix
    ./wm/hyprland.nix
  ];

  programs.waybar = {
    enable = true;
    style = ''
      window#waybar {
        background-color: #ff5fd7;
      }
    '';
    settings = {
      main = {
        modules-right = ["battery" "clock"];
	
      };
    };
  };

  programs.home-manager = { 
    enable = true;
  };

  programs.fastfetch = {
    enable = true;
  };

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ~/Wallpapers/toradora.png
    wallpaper = , ~/Wallpapers/toradora.png
  '';

  home.file.".config/bat/config".text = ''
     --theme="Nord"
     --style="numbers,changes,grid"
     --paging=auto
   '';

  home.file.".config/qtile".source = ./qtile;
}

