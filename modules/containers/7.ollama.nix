{ config, lib, ... }:
let
  isDesktop = config.profile.isRole [ "desktop" ];
in
{
  services.ollama = {
    enable = true;
    host   = "0.0.0.0";
    acceleration = lib.mkIf isDesktop "rocm";
    models = "/home/jakub/data/ollama-models";
  };
  
  fileSystems."/var/lib/ollama-models" = {
    device  = "/home/jakub/data/ollama-models";
    options = [ "bind" ];
  };

  systemd.tmpfiles.rules = [
    "d /home/jakub/data/ollama-models 0755 root root - -"
    "d /var/lib/ollama-models         0755 root root - -"
  ];
}