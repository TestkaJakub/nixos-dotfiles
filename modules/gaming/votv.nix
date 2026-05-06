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

      sourceRoot = ".";
      
	  nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

	  installPhase = ''
	    mkdir -p $out/bin
	    substitute YeetPatch.sh $out/bin/.yeetpatch-wrapped \
	      --replace-fail 'DESYNC_BIN="$SCRIPT_DIR/desync"' 'DESYNC_BIN="desync"'
	    chmod +x $out/bin/.yeetpatch-wrapped
	    wrapProgram $out/bin/.yeetpatch-wrapped \
	      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.jq pkgs.curl pkgs.desync ]}
	    mv $out/bin/.yeetpatch-wrapped $out/bin/yeetpatch
	  '';
    })
  ];
}
