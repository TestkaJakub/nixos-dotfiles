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

  services.xserver = lib.mkIf isDesktop {
    enable       = true;
    videoDrivers = [ "nvidia" ];
    deviceSection = ''
      Option "Coolbits" "4"
    '';
    screenSection = ''
      Option "metamodes" "CurrentMetaMode="HDMI-0: 1920x1080_60 +0+0 {ViewPortIn=1920x1080, ViewPortOut=1820x1024+50+28}"
    '';
  };

  environment = lib.mkIf isDesktop {
    systemPackages   = [ pkgs.nvtopPackages.full ];
    sessionVariables = {
      NVD_BACKEND              = "direct";
      LIBVA_DRIVER_NAME        = "nvidia";
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
