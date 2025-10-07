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
    ./programs/bat.nix
    ./programs/hyprpaper.nix
    ./programs/waybar.nix
    ./wm/hyprland.nix
  ];
  
  programs.home-manager.enable = true;
  programs.fastfetch.enable = true;
  programs.firefox.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  home.file.".config/qtile".source = ./qtile;
}
