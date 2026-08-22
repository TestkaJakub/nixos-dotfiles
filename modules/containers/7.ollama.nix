{ config, lib, ... }:
let
  isDesktop = config.profile.isRole [ "desktop" ];
in
{
  services.ollama = {
    enable = true;
    host   = "0.0.0.0";
    acceleration = lib.mkIf isDesktop "rocm";
    models = lib.mkIf isDesktop "/home/jakub/data/ollama-models";
  };

  systemd.tmpfiles.rules = [
    "d /home/jakub/data/ollama-models 0755 ollama ollama - -"
  ];
}