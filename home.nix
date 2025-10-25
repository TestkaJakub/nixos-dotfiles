# home.nix
{ config, pkgs, lib, inputs, system, ... }:

let
  confDir = ./home-config;
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
  ];

  modules = map (file: confDir + ("/" + file)) moduleFiles;
in
{
  imports = modules;

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
      wget
      pfetch-rs
      kitty
      fuzzel
      obsidian
      scrcpy
      wl-clipboard
      pamixer
      pastel
    ];
  };

  programs.home-manager.enable = true;

  wayland.windowManager.mango.enable = true;

  home.file.".config/qtile".source = confDir + "/qtile";
}
