{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      pname   = "yeetpatch";
      version = "latest2";

      src = pkgs.fetchurl {
        url    = "https://votv.dev/patcher_assets/download/YeetPatch-latest-linux.tar";
        sha256 = "sha256-zlvwkHlixxudPagUDYnbBP/R4fFZbBE+lmS5Vngvjcs=";
      };

      installPhase = ''
        ls -laR .
        mkdir -p $out/bin
      '';
    })
  ];
}
