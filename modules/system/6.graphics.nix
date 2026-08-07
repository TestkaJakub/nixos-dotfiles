{ pkgs, config, lib, ... }:

# ── Graphics ───────────────────────────────────────────────────────────────────
# Base Mesa (OpenGL + Vulkan) for every graphical machine.
# Desktop additionally drives a discrete AMD Radeon RX 9070 XT (RDNA 4 / gfx1201).
#
# RDNA 4 requirements: Mesa >= 25.0 (nixos-25.11 already ships 25.x) and a recent
# kernel (6.12 is the floor, newer is better) — we pull linuxPackages_latest below
# so the amdgpu kernel driver is as new as possible.
#
# amdgpu is loaded automatically by the kernel; RADV (Vulkan) and RadeonSI
# (OpenGL) come from Mesa. No proprietary driver, no DKMS, no out-of-tree patches.
#
# Verify after a rebuild:
#   nix shell nixpkgs#mesa-demos  -c glxinfo | grep "OpenGL renderer"   # -> AMD ...
#   vulkaninfo | grep "deviceName"                                       # -> RADV ...
#   vainfo                                                               # -> VA-API OK
let
  isDesktop = config.profile.isRole [ "desktop" ];
in
{
  hardware = {
    graphics = {
      enable      = true;
      enable32Bit = true;
      extraPackages = lib.optionals isDesktop (with pkgs; [
        libva-vdpau-driver   # VDPAU -> VA-API bridge
        libvdpau-va-gl       # VA-API -> VDPAU bridge
        # OpenCL on gfx1201 (RDNA 4) via ROCm is still maturing. Uncomment if/when
        # you need GPU compute and are willing to test it:
        # rocmPackages.clr.icd
      ]);
    };

    # RDNA 4 firmware blobs live in linux-firmware — make sure they're present.
    enableRedistributableFirmware = lib.mkIf isDesktop true;

    # Load amdgpu in the initrd for clean KMS from the very first frame.
    amdgpu.initrd.enable = lib.mkIf isDesktop true;
  };

  # ── Kernel ────────────────────────────────────────────────────────────────
  # Newest kernel for the best RDNA 4 amdgpu support. Desktop only — the
  # workstation stays on the default LTS kernel.
  boot = lib.mkIf isDesktop {
    kernelPackages = pkgs.linuxPackages_latest;

    # Unlock the full power/clock table so LACT can undervolt/overclock —
    # this replaces the old NVIDIA "Coolbits" overclocking workflow.
    kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
  };

  # ── Xorg ──────────────────────────────────────────────────────────────────
  # i3 runs on X11 (see desktop/i3.nix). amdgpu is the Xorg driver.
  #
  # NOTE: the old NVIDIA metamodes (2624x1476 -> 1920x1080 supersampling) and
  # Coolbits were NVIDIA-only and have no xorg.conf equivalent on amdgpu, so
  # they're gone — you now render at native 1080p. If you want the old
  # supersampling back, use per-game render scale, or:
  #   xrandr --output HDMI-A-1 --scale 1.37x1.37
  # (the connector is now named e.g. HDMI-A-1 / DP-1, not HDMI-0 — check with
  #  `xrandr` while your monitor is connected.)
  services.xserver = lib.mkIf isDesktop {
    enable       = true;
    videoDrivers = [ "amdgpu" ];
  };

  # ── Environment ───────────────────────────────────────────────────────────
  environment = lib.mkIf isDesktop {
    systemPackages = with pkgs; [
      nvtopPackages.amd   # GPU monitor (AMD build)
      libva-utils         # vainfo — verify VA-API decode
      vulkan-tools        # vulkaninfo — verify RADV
    ];

    sessionVariables = {
      LIBVA_DRIVER_NAME = "radeonsi";   # was "nvidia"
      QT_FONT_DPI       = "131";
    };

    etc."ld.so.conf.d/nixos-opengl.conf".text = ''
      /run/opengl-driver/lib
      /run/opengl-driver-32/lib
    '';
  };

  # ── LACT — AMD overclock / undervolt / fan control ────────────────────────
  # Replaces the NVIDIA Coolbits overclocking you had before. Runs a daemon
  # (lactd) + polkit rules; launch the `lact` GUI to tune. Needs the
  # amdgpu.ppfeaturemask kernel param set above to expose the full pp_od table.
  services.lact.enable = lib.mkIf isDesktop true;

  # ── Steam / pressure-vessel ldconfig cache (unchanged, GPU-agnostic) ──────
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