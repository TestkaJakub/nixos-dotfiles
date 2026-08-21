{ config, lib, ... }:
let
  isDesktop = config.profile.isRole [ "desktop" ];
in
{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      userland-proxy = true;
      experimental   = true;
      dns = lib.mkIf isDesktop [ "1.1.1.1" "8.8.8.8" ];
    };
  };

  virtualisation.oci-containers.backend = "docker";
}