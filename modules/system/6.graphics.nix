{ pkgs, config, lib, ... }:
let
  isDesktop = config.profile.isRole [ "personal" ];
  isServer  = config.profile.isRole [ "server" ];
in
{
  hardware = {
    graphics = {
      enable      = true;
      enable32Bit = true;
      extraPackages = lib.optionals isDesktop (with pkgs; [
        nvidia-vaapi-driver
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
  };

  environment = {
    systemPackages   = lib.optionals (!isServer) [ pkgs.nvtopPackages.full ];
    sessionVariables = lib.mkIf isDesktop {
      NVD_BACKEND              = "direct";
      LIBVA_DRIVER_NAME        = "nvidia";
      NIXOS_OZONE_WL           = "1";
      # These two are needed so KWin uses the NVIDIA GBM backend
      GBM_BACKEND              = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };

  boot.kernelParams = lib.mkIf isDesktop [ "nvidia-drm.modeset=1" ];
}