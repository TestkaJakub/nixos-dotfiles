{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true;

    package = pkgs.steam.override {
      extraPackages = with pkgs; [
        mesa
        mesa.drivers
        libdrm
      ];
    };
  };

  # Optional: enable 32‑bit OpenGL and Vulkan components
  hardware.opengl.driSupport32Bit = true;
}
