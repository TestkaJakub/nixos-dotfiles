{ pkgs, ... }:

let
  appImagePath = pkgs.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v02.04.00.70/Bambu_Studio_ubuntu-22.04_PR-8834.AppImage";
    sha256 = "ff17150f760fb80afc98d9841b134c0bada4897d6aaf36808b517a4bed2c11b0";
  };

  bambuStudioFhs = pkgs.buildFHSUserEnv {
    name = "bambu-studio-fhs";
    targetPkgs = pkgs: with pkgs; [
      # Core system and GUI runtime
      stdenv.cc.cc.lib
      zlib fontconfig freetype mesa libGL glib gtk3 gdk-pixbuf pango cairo atk
      webkitgtk_4_1 libsoup_3 enchant2 harfbuzz icu
      gst_all_1.gstreamer gst_all_1.gst-libav gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good gst_all_1.gst-plugins-bad ffmpeg
      xorg.libX11 xorg.libXext xorg.libxcb wayland libxkbcommon
      at-spi2-core dbus gsettings-desktop-schemas
    ];
    runScript = pkgs.writeScript "bambu-studio-run" ''
      #!/usr/bin/env bash
      tmpApp="/tmp/bambu-studio.AppImage"
      cp ${appImagePath} "$tmpApp"
      chmod +x "$tmpApp"
      exec "$tmpApp" "$@"
    '';
  };
in {
  home.packages = [ bambuStudioFhs ];

  xdg.desktopEntries.bambu-studio = {
    name = "Bambu Studio (FHS)";
    comment = "3D printing software for Bambu Lab printers";
    exec = "env QT_QPA_PLATFORM=xcb ${bambuStudioFhs}/bin/bambu-studio-fhs";
    icon = "application-x-executable";
    categories = [ "Graphics" "Engineering" ];
    type = "Application";
    terminal = false;
  };
}
