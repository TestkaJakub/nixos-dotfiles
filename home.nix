# home.nix
{ config, pkgs, lib, inputs, system, homeConfigurationPath, user, version ... }:

let
  moduleFiles = [
    "bash.nix"
    "alacritty.nix"
    "fuzzel.nix"
    "neovim.nix"
    "bat.nix"
    "waybar.nix"
    "zoxide.nix"
    "fastfetch.nix"
    "firefox.nix"
    "swww.nix"
    "mango.nix"
    "gammastep.nix"
  ];

  modules = map (file: homeConfigurationPath + ("/" + file)) moduleFiles;
in
{
  imports = modules;

  home = {
    username = user;
    stateVersion = version;
    sessionVariables.NIXOS_OZONE_WL = "1";

    packages = with pkgs; [
      android-studio
      bat
      btop
      git
      arduino-core
      arduino-cli
      fastfetch
      wget
      pfetch-rs
      kitty
      fuzzel
      obsidian
      scrcpy
      wl-clipboard
      pamixer
      pastel
      hyprpaper
      anki-bin
      mpv
    ];
  };

  programs.home-manager.enable = true;

  wayland.windowManager.mango.enable = true;

  # home.file.".config/qtile".source = homeConfigurationPath + "/qtile";
}
