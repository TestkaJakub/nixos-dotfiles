{ pkgs, config, lib, ... }:

# ── Graphics ───────────────────────────────────────────────────────────────────
# Base Mesa (OpenGL + Vulkan) for every graphical machine.
# Desktop additionally drives a discrete AMD Radeon RX 9070 XT (RDNA 4 / gfx1201).
let
  isDesktop = config.profile.isRole [ "desktop" ];
in
{
  hardware = {
    graphics = {
      enable      = true;
      enable32Bit = true;
      extraPackages = lib.optionals isDesktop (with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ]);
    };

    enableRedistributableFirmware = lib.mkIf isDesktop true;
    amdgpu.initrd.enable          = lib.mkIf isDesktop true;
  };

  boot = lib.mkIf isDesktop {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams   = [ "amdgpu.ppfeaturemask=0xffffffff" ];
  };

  # ── Xorg ──────────────────────────────────────────────────────────────────
  # videoDrivers = "modesetting" (not "amdgpu") + SWcursor is the confirmed fix
  # for the floaty/gliding cursor seen after NVIDIA -> RDNA 4 swaps (same
  # symptom reported on the Arch forum: 2080ti -> 9070XT, X11). The amdgpu
  # kernel driver still handles actual GPU rendering via Mesa/RADV underneath —
  # this only changes which Xorg DDX drives the display server and cursor
  # presentation, which is exactly where the gliding was coming from.
  services.xserver = lib.mkIf isDesktop {
    enable        = true;
    videoDrivers  = [ "modesetting" ];
    deviceSection = ''
      Identifier "AMD"
      Driver "modesetting"
      Option "SWcursor" "True"
    '';
  };

  environment = lib.mkIf isDesktop {
    systemPackages = with pkgs; [
      nvtopPackages.amd
      libva-utils
      vulkan-tools
    ];

    sessionVariables = {
      LIBVA_DRIVER_NAME = "radeonsi";
      QT_FONT_DPI       = "131";
    };

    etc."ld.so.conf.d/nixos-opengl.conf".text = ''
      /run/opengl-driver/lib
      /run/opengl-driver-32/lib
    '';
  };

  services.lact.enable = lib.mkIf isDesktop true;

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