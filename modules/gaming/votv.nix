{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      pname   = "yeetpatch";
      version = "latest4";

      src = pkgs.fetchurl {
        url    = "https://votv.dev/patcher_assets/download/YeetPatch-latest-linux.tar";
        sha256 = "sha256-zlvwkHlixxudPagUDYnbBP/R4fFZbBE+lmS5Vngvjcs=";
      };

      sourceRoot = ".";

      nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

      installPhase = ''
        mkdir -p $out/bin
        substitute YeetPatch.sh $out/bin/yeetpatch \
          --replace-fail \
            'DESYNC_BIN="$SCRIPT_DIR/desync"' \
            'DESYNC_BIN="$(command -v desync)"' \
          --replace-fail \
            'if [[ -x "$DESYNC_BIN" ]]; then' \
            'if [[ -n "$DESYNC_BIN" ]]; then'
        chmod +x $out/bin/yeetpatch
        wrapProgram $out/bin/yeetpatch \
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.jq pkgs.curl pkgs.desync ]}
      '';
    })
  ];
}
