{ config, pkgs, lib, inputs, system, homeConfigurationPath, user, version, theme, ... }:

let
  moduleFiles = [
    "bash.nix"
    "neovim.nix"
    "bat.nix"
    "waybar.nix"
    "zoxide.nix"
    "fastfetch.nix"
    "firefox.nix"
    "swww.nix"
    "mango.nix"
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
      #androidsdk
      android-tools
      jdk
      gradle
      bat
      git
      arduino-core
      arduino-cli
      fastfetch
      wget
      pfetch-rs
      obsidian
      scrcpy
      wl-clipboard
      pamixer
      #pastel
      hyprpaper
      anki-bin
      mpv
      gammastep
    ];
  };

  nixpkgs.config.android_sdk.accept_license = true;

  programs.home-manager.enable = true;

  wayland.windowManager.mango.enable = true;

  home.sessionVariables.CAPACITOR_ANDROID_STUDIO_PATH = "${pkgs.android-studio}/bin/android-studio";

  # home.file.".config/qtile".source = homeConfigurationPath + "/qtile";
}
