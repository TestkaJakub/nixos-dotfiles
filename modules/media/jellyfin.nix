{ pkgs, config, ... }:
let
  user = config.profile.username;
  shim = pkgs.jellyfin-mpv-shim;
  wrapper = pkgs.writeShellScriptBin "jellyfin-mpv-shim" ''
    export SSL_CERT_FILE="/home/${config.profile.username}/.step/certs/root_ca.crt"
    exec ${shim}/bin/jellyfin-mpv-shim "$@"
  '';
in
{
  home-manager.users.${user}.home.packages = [ wrapper ];
}
