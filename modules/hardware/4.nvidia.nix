{ pkgs, lib, config, ... }:

{
  # Load nvidia driver for Xorg and Wayland
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable  = true;
    powerManagement.enable = false;
    open   = false;          # GTX 660 is Kepler — must use closed source
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
    # GTX 660 (GK106) needs the 470.xx legacy driver
  };

  environment.systemPackages = [ pkgs.nvtopPackages.full ];
}
