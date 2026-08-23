{ ... }:
{
  services.ollama = {
    enable = true;
    host   = "0.0.0.0";
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