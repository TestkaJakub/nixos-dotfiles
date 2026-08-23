{ config, lib, ... }:
let
  isDesktop = config.profile.isRole [ "desktop" ];
in
{
  services.ollama = {
    enable = true;
    host   = "0.0.0.0";
    acceleration    = lib.mkIf isDesktop "rocm";
    rocmOverrideGfx = lib.mkIf isDesktop "12.0.1";  # gfx1201, matches this card
  };

  systemd.tmpfiles.rules = [
    "d /home/jakub/data/ollama-store 0755 root root - -"
  ];

  fileSystems."/var/lib/private/ollama" = {
    device  = "/home/jakub/data/ollama-store";
    options = [ "bind" "nofail" ];
    depends = [ "/home/jakub/data" ];
  };
}