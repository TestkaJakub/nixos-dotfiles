{ pkgs, config, ... }:
let
  user = config.profile.username;
  shim = pkgs.jellyfin-mpv-shim.overridePythonAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      find $out/lib -name "cacert.pem" -exec sh -c \
        'cat ${../meta/homelab-root.crt} ${../meta/homelab-intermediate.crt} >> {}' \;
    '';
  });
  bundle = pkgs.runCommand "combined-ca-bundle" {} ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
        ${../meta/homelab-root.crt} \
        ${../meta/homelab-intermediate.crt} > $out
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
