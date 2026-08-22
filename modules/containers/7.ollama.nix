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

  # NixOS sandboxes the ollama service with ProtectHome, which hides /home
  # from it entirely — so it can't reach the data disk mounted under
  # /home/jakub/data. Disable that protection so it can see the path.
  systemd.services.ollama.serviceConfig.ProtectHome = lib.mkForce false;

  # Create the models dir owned by the ollama service user.
  systemd.tmpfiles.rules = [
    "d /home/jakub/data/ollama-models 0755 ollama ollama - -"
  ];
}