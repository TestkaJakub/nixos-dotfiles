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
    #"bambu-studio.nix"
  ];

  modules = map (file: homeConfigurationPath + ("/" + file)) moduleFiles;
  geProton = builtins.fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-28/GE-Proton10-28.tar.gz";
    sha256 = "05p39lnai27m5qvp401b0wpdic0d8z4hpih21rhkzx8sgxpc8p2c";
  };

  bambu-studio-appimage = pkgs.appimageTools.wrapType2 rec {
    name = "BambuStudio";
    pname = "bambustudio";
    shortversion = "2.04";
    version = "0${shortversion}.00.70";
    pr = "PR-8834";
    src = pkgs.fetchurl {
      url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-2${shortversion}_${pr}.AppImage";
      sha256 = "/xcVD3YPuAr8mNmEGxNMC62kiX1qrzaAi1F6S+0sEbA=";
    };
    profile = ''
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules/"
    '';
    extraPkgs = pkgs: with pkgs; [
      cacert
      curl
      glib
      glib-networking
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      webkitgtk_6_0
    ];
  };
in
{
  imports = modules;

  home = {
    username = user;
    stateVersion = version;
    sessionVariables.NIXOS_OZONE_WL = "1";

activation.installProtonGE = lib.hm.dag.entryAfter ["writeBoundary"] ''
  DEST="$HOME/.local/share/Steam/compatibilitytools.d"
  mkdir -p "$DEST"
  rm -rf "$DEST/GE-Proton10-28"
  echo "📦 Unpacking GE‑Proton10‑28 into Steam compatibilitytools.d"
  ${pkgs.gnutar}/bin/tar --use-compress-program=${pkgs.gzip}/bin/gzip \
    -x -f ${geProton} -C "$DEST"
  echo "✅ GE‑Proton10‑28 ready for Steam"
'';

    packages = with pkgs; [
      android-studio
      grim
      slurp
      wev
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
      steam-unwrapped
      steam-run
      bambu-studio-appimage
      (writeShellScriptBin "screenshot-region" ''
        mkdir -p ~/Pictures/screenshots
        grim -g "$(slurp)" ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy
        notify-send "✅ Screenshot copied to clipboard"
      '')
      (writeShellScriptBin "screenshot-full" ''
        mkdir -p ~/Pictures/screenshots
        grim ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
        notify-send "✅ Fullscreen screenshot saved"
      '')
      (writeShellScriptBin "bambu-studio" ''
	exec ${bambu-studio-appimage}/bin/bambustudio "$@"
      '')
    ];
  };

  programs.home-manager.enable = true;

  xdg.desktopEntries.bambu-studio = {
    name = "Bambu Studio";
    comment = "3D printing software for Bambu Lab printers";
    exec = "env QT_QPA_PLATFORM=xcb bambu-studio";
    icon = "application-x-executable";
    categories = [ "Graphics" "Engineering" ];
    type = "Application";
    terminal = false;
  };

  wayland.windowManager.mango.enable = true;

  home.sessionVariables = { 
    CAPACITOR_ANDROID_STUDIO_PATH = "${pkgs.android-studio}/bin/android-studio";
    ANDROID_HOME = "/home/jakub/Android/Sdk";
    ANDROID_SDK_ROOT = "/home/jakub/Android/Sdk";
  };

  # home.file.".config/qtile".source = homeConfigurationPath + "/qtile";
}
