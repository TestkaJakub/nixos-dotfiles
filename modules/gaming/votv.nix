{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      pname   = "yeetpatch";
      version = "latest";

      src = pkgs.fetchurl {
        url    = "https://votv.dev/patcher_assets/download/YeetPatch-latest-linux.tar";
        sha256 = pkgs.lib.fakeHash;
      };

      installPhase = ''
        ls -la
        mkdir -p $out/bin
      '';
    })
  ];
}
