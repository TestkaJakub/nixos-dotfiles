{ pkgs, ... }:

let
  bambuStudio = pkgs.appimageTools.wrapType2 {
    name = "bambu-studio";
    src = pkgs.fetchurl {
      url = "https://github.com/bambulab/BambuStudio/releases/download/v02.04.00.70/Bambu_Studio_ubuntu-22.04_PR-8834.AppImage";
      sha256 = "ff17150f760fb80afc98d9841b134c0bada4897d6aaf36808b517a4bed2c11b0";
    };
    extraPkgs = pkgs: with pkgs; [ libGL zlib ];
  };
in {
  home.packages = [ bambuStudio ];
}
