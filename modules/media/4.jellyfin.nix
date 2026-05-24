{ pkgs, config, ... }:
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.home.packages = [ pkgs.jellyfin-mpv-shim ];
}
