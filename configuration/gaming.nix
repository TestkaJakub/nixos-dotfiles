{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      libdrm
    ];
  };

  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        mesa
        libdrm
      ];
    };
  };

  # Optional but helps FHS sandbox compatibility
  environment.systemPackages = with pkgs; [
    vulkan-tools       # provides vulkaninfo
    glxinfo            # from mesa-demos
  ];
}
