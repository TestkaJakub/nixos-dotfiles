{ pkgs, config, lib, ... }:

# ── Peripherals ────────────────────────────────────────────────────────────────
{
  hardware.bluetooth = lib.mkIf config.profile.hasBluetooth {
    enable      = true;
    powerOnBoot = true;
  };
  hardware.opentabletdriver.enable = lib.mkIf config.profile.hasTablet true;
  hardware.uinput.enable           = lib.mkIf config.profile.hasTablet true;
  services.blueman.enable = lib.mkIf config.profile.hasBluetooth true;

  # Storage / removable media — gvfs declared once here, not in filemanager.nix
  services.devmon.enable  = true;
  services.gvfs.enable    = true;
  services.udisks2.enable = true;


  # Keyboard backlight — dedicated group + one-shot service so kbm() works
  # without sudo on every boot.
  users.groups.backlight = lib.mkIf config.profile.hasBacklight {};
  users.users.${config.profile.username}.extraGroups = lib.mkIf config.profile.hasBacklight [ "backlight" ];

  systemd.services.kbd-backlight-perms = lib.mkIf config.profile.hasBacklight {
    description     = "Set keyboard backlight brightness group to backlight";
    wantedBy        = [ "multi-user.target" ];
    after           = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart       = pkgs.writeShellScript "kbd-backlight-perms" ''
        ${pkgs.coreutils}/bin/chown root:backlight \
          /sys/class/leds/tpacpi::kbd_backlight/brightness
        ${pkgs.coreutils}/bin/chmod g+w \
          /sys/class/leds/tpacpi::kbd_backlight/brightness
      '';
    };
  };
}
