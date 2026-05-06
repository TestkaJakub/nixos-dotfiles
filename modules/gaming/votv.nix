{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      pname   = "yeetpatch";
      version = "latest";

      src = pkgs.fetchurl {
        url    = "https://votv.dev/patcher_assets/download/YeetPatch-latest-linux.tar";
        sha256 = "sha256-zlvwkHlixxudPagUDYnbBP/R4fFZbBE+lmS5Vngvjcs=";
      };

      installPhase = ''
        mkdir -p $out/bin
        cp YeetPatch.sh $out/bin/yeetpatch
        chmod +x $out/bin/yeetpatch
      '';
    })
  ];
}
