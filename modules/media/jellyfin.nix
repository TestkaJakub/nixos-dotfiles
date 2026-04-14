{ pkgs, config, ... }:
let
  user = config.profile.username;
	shim = pkgs.jellyfin-mpv-shim.override {
	  python = pkgs.python3.override {
	    packageOverrides = self: super: {
	      certifi = super.certifi.overrideAttrs (old: {
	        postInstall = (old.postInstall or "") + ''
	          cat ${../meta/homelab-root.crt} ${../meta/homelab-intermediate.crt} \
	            >> $out/lib/python*/site-packages/certifi/cacert.pem
	        '';
	      });
	    };
	  };
	};
  bundle = pkgs.runCommand "combined-ca-bundle" {} ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
        ${builtins.path { path = ../meta/homelab-root.crt; name = "homelab-root.crt"; }} \
        ${builtins.path { path = ../meta/homelab-intermediate.crt; name = "homelab-intermediate.crt"; }} > $out
  '';
	wrapper = pkgs.writeShellScriptBin "jellyfin-mpv-shim" ''
	  export SSL_CERT_FILE="${bundle}"
	  export REQUESTS_CA_BUNDLE="${bundle}"
	  export WEBSOCKET_CLIENT_CA_BUNDLE="${bundle}"
	  export PYTHONHTTPSVERIFY=0
	  exec ${shim}/bin/jellyfin-mpv-shim "$@"
	'';
in
{
  home-manager.users.${user}.home.packages = [ wrapper ];
}
