{ config, pkgs, ... }:
{
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    flags = [
      "--cmd cd"
    ];
  };
}
