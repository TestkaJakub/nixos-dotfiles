{ pkgs, config, ... }:

# ── Bambu Studio ───────────────────────────────────────────────────────────────
# 3D printing slicer for Bambu Lab printers.
# Distributed as an AppImage; wrapped with appimageTools for NixOS compatibility.
# AppImage binfmt support is enabled in system/nix.nix.
#
# Placed in others/ because 3D printing has no peer in the current system.
# If other fabrication tools are added later, consider a making/ directory.
let
  user = config.profile.username;

  bambu-studio-appimage = pkgs.appimageTools.wrapType2 rec {
    name         = "BambuStudio";
    pname        = "bambustudio";
    shortversion = "2.04";
    version      = "0${shortversion}.00.70";
    pr           = "PR-8834";

    src = pkgs.fetchurl {
      url    = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-2${shortversion}_${pr}.AppImage";
      sha256 = "/xcVD3YPuAr8mNmEGxNMC62kiX1qrzaAi1F6S+0sEbA=";
    };

    profile = ''
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules/"
      export LANGUAGE=en_US.UTF-8
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
    '';

    extraPkgs = p: with p; [
      cacert glib glib-networking glibcLocales curl
      webkitgtk_4_0
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
    ];

    extraInstallCommands = ''
      mkdir -p $out/lib/locale
      ln -sf ${pkgs.glibcLocales}/lib/locale/locale-archive $out/lib/locale/locale-archive
    '';
  };

  # Thin wrapper so the binary name is simply "bambu-studio"
  launcher = pkgs.writeShellScriptBin "bambu-studio" ''
    exec ${bambu-studio-appimage}/bin/bambustudio "$@"
  '';
in
{
  home-manager.users.${user} = {
    home.packages = [ bambu-studio-appimage launcher ];

    xdg.desktopEntries.bambu-studio = {
      name       = "Bambu Studio";
      comment    = "3D printing slicer for Bambu Lab printers";
      exec       = "env QT_QPA_PLATFORM=xcb bambu-studio";
      icon       = "application-x-executable";
      categories = [ "Graphics" "Engineering" ];
      type       = "Application";
      terminal   = false;
    };
  };
}
