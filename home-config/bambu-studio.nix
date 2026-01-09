{ pkgs, ... }:

let
  bambuStudio = pkgs.appimageTools.wrapType2 {
    pname = "bambu-studio";
    version = "2.04.00.70";

    src = pkgs.fetchurl {
      url = "https://github.com/bambulab/BambuStudio/releases/download/v02.04.00.70/Bambu_Studio_ubuntu-22.04_PR-8834.AppImage";
      sha256 = "ff17150f760fb80afc98d9841b134c0bada4897d6aaf36808b517a4bed2c11b0";
    };

    extraPkgs = pkgs: with pkgs; [
      glib
      gtk3
      webkitgtk
      mesa
      libGL
      zlib
      xorg.libX11
      xorg.libXext
      xorg.libxcb
      dbus
      libdrm
      pango
      cairo
      at-spi2-core
      gsettings-desktop-schemas
    ];
  };
in {
  home.packages = [ bambuStudio ];

  xdg.desktopEntries.bambu-studio = {
    name = "Bambu Studio";
    comment = "3D printing software for Bambu Lab printers";
    exec = "env GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb ${bambuStudio}";
    icon = "${bambuStudio}/share/icons/hicolor/256x256/apps/bambu-studio.png";
    categories = [ "Graphics" "Engineering" "X-3DPrinting" ];
    type = "Application";
    terminal = false;
  };
}
