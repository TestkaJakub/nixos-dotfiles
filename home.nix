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
      pamixer
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
    ./programs/zoxide.nix
    ./programs/fastfetch.nix
    ./programs/firefox.nix
    ./wm/hyprland.nix
  ];
  
  programs.home-manager.enable = true;

  home.file.".config/qtile".source = ./qtile;
}
