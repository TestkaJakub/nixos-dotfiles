{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true;

    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        mesa
        mesa.drivers
        libdrm
      ];
    };
  };

  # Modern graphics option names
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
