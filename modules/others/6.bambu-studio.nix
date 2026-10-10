{ pkgs, config, ... }:

# ── Bambu Studio ───────────────────────────────────────────────────────────────
# 3D printing slicer for Bambu Lab printers, from the official AppImage.
# Not taken from nixpkgs: it's unfree, so Hydra never caches it and every
# update means a long local compile.
#
# To update — https://github.com/bambulab/BambuStudio/releases/latest → Assets:
#   version  from the tag             (v02.08.02.61 → "02.08.02.61")
#   build    timestamp in file name   (…-v02.08.02.61-20260820225108.AppImage)
#   sha256   shown next to the ubuntu24.04 AppImage
# then: nrs
let
  user = config.profile.username;

  version = "02.08.02.61";
  build   = "20260820225108";
  sha256  = "d501b103fac5424513ec0e8d6bc145fb30719de2c7d94d7320d723740c81a7fd";

  bambu-studio = pkgs.appimageTools.wrapType2 {
    pname = "bambu-studio";   # → $out/bin/bambu-studio
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu24.04-v${version}-${build}.AppImage";
      inherit sha256;
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
      webkitgtk_4_1
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
    ];
  };
in
{
  home-manager.users.${user} = {
    home.packages = [ bambu-studio ];

    xdg.desktopEntries.bambu-studio = {
      name       = "Bambu Studio";
      comment    = "3D printing slicer for Bambu Lab printers";
      exec       = "bambu-studio %F";
      icon       = "application-x-executable";
      categories = [ "Graphics" "Engineering" ];
      terminal   = false;
    };
  };
}