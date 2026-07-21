{ pkgs, config, lib, ... }:
let
  isDesktop = config.profile.isRole [ "desktop" ];
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
        ocl-icd
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

  sservices.xserver = lib.mkIf isDesktop {
    enable       = true;
    videoDrivers = [ "nvidia" ];
    deviceSection = ''
      Option "Coolbits" "4"
    '';
    screenSection = ''
      Option "metamodes" "HDMI-0: 1920x1080_60 { ViewPortIn=2624x1476, ViewPortOut=1920x1080+0+0 }"
    '';
  };

  environment = lib.mkIf isDesktop {
    systemPackages   = [ pkgs.nvtopPackages.full ];
    sessionVariables = {
      NVD_BACKEND       = "direct";
      LIBVA_DRIVER_NAME = "nvidia";
      QT_FONT_DPI       = "131";
    };
    etc."ld.so.conf.d/nixos-opengl.conf".text = ''
      /run/opengl-driver/lib
      /run/opengl-driver-32/lib
    '';
  };

  boot.kernelParams = lib.mkIf isDesktop [ "nvidia-drm.modeset=1" ];

  systemd.services.ldconfig-steam = lib.mkIf isDesktop {
    description = "Generate ldconfig cache for Steam/pressure-vessel";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ldconfig-steam" ''
        ${pkgs.glibc.bin}/bin/ldconfig -C /etc/ld.so.cache
      '';
    };
  };
}
