{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      pname   = "yeetpatch";
      version = "latest3";

      src = pkgs.fetchurl {
        url    = "https://votv.dev/patcher_assets/download/YeetPatch-latest-linux.tar";
        sha256 = "sha256-zlvwkHlixxudPagUDYnbBP/R4fFZbBE+lmS5Vngvjcs=";
      };

      sourceRoot = ".";
      
	  nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

		installPhase = ''
		  set -x
		  mkdir -p $out/bin
		  cp YeetPatch.sh $out/bin/yeetpatch
		  grep "DESYNC_BIN" $out/bin/yeetpatch
		  substitute $out/bin/yeetpatch $out/bin/yeetpatch \
		    --replace-fail 'DESYNC_BIN="$SCRIPT_DIR/desync"' 'DESYNC_BIN="desync"'
		  grep "DESYNC_BIN" $out/bin/yeetpatch
		  chmod +x $out/bin/yeetpatch
		  wrapProgram $out/bin/yeetpatch \
		    --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.jq pkgs.curl pkgs.desync ]}
		'';
    })
  ];
}
