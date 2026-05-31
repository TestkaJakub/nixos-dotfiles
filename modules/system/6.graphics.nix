{ pkgs, config, lib, ... }:
let
  isDesktop = config.profile.isRole [ "personal" ];
in
{
  hardware = {
    graphics = {
      enable      = true;
      enable32Bit = true;
      extraPackages = lib.optionals isDesktop (with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ]);
    };
    nvidia = lib.mkIf isDesktop {
      modesetting.enable     = true;
      powerManagement.enable = false;
      open                   = false;
      nvidiaSettings         = true;
      package                = config.boot.kernelPackages.nvidiaPackages.legacy_470;
    };
  };

  services.xserver = lib.mkIf isDesktop {
    enable       = true;
    videoDrivers = [ "nvidia" ];
    deviceSection = ''
      Option "Coolbits" "4"
    '';
  };

  environment = lib.mkIf isDesktop {
    systemPackages   = [ pkgs.nvtopPackages.full ];
    sessionVariables = {
      NVD_BACKEND              = "direct";
      LIBVA_DRIVER_NAME        = "nvidia";
    };
  };

  boot.kernelParams = lib.mkIf isDesktop [ "nvidia-drm.modeset=1" ];
}