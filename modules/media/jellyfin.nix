{ pkgs, config, ... }:
let
  user = config.profile.username;
  bundle = pkgs.runCommand "combined-ca-bundle-v3" {} ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
        ${../meta/homelab-root.crt} \
        ${../meta/homelab-intermediate.crt} > $out
  '';
  shim = pkgs.jellyfin-mpv-shim.overrideAttrs (old: {
    makeWrapperArgs = (old.makeWrapperArgs or []) ++ [
      "--set" "WEBSOCKET_CLIENT_CA_BUNDLE" "${bundle}"
      "--set" "REQUESTS_CA_BUNDLE" "${bundle}"
      "--set" "SSL_CERT_FILE" "${bundle}"
    ];
  });
in
{
  home-manager.users.${user}.home.packages = [ shim ];
}
