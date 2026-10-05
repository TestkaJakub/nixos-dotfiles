{ config, lib, ... }:

# ── Boot & locale ──────────────────────────────────────────────────────────────
# Reads: config.locale.{consoleKeyMap, keyboardLayout, timezone,
#                        defaultLocale, extraLocales}
{
  time.timeZone = config.locale.timezone;

  i18n = {
    defaultLocale = config.locale.defaultLocale;
    extraLocales  = config.locale.extraLocales;
  };

  console.keyMap = config.locale.consoleKeyMap;

  services.xserver.xkb = lib.mkIf (config.profile.isRole [ "workstation" "desktop" ]) {
    layout  = config.locale.keyboardLayout;
    variant = "";
  };

  boot = {
    supportedFilesystems = [ "ntfs" ];
    loader = {
      systemd-boot.enable      = true;
      efi.canTouchEfiVariables = true;
    };
    # uinput required by OpenTabletDriver (kvm-amd comes from hardware.nix)
    kernelModules = [ "uinput" ];
  };
}
