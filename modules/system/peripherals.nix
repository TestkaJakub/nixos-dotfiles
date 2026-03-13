{ pkgs, config, ... }:

# ── Peripherals ────────────────────────────────────────────────────────────────
{
  # Bluetooth
  services.blueman.enable = true;

  # Storage / removable media — gvfs declared once here, not in filemanager.nix
  services.devmon.enable  = true;
  services.gvfs.enable    = true;
  services.udisks2.enable = true;

  # Graphics tablets
  hardware.opentabletdriver.enable = true;
  hardware.uinput.enable           = true;

  # Keyboard backlight — dedicated group + one-shot service so kbm() works
  # without sudo on every boot.
  users.groups.backlight = {};
  users.users.${config.profile.username}.extraGroups = [ "backlight" ];

  systemd.services.kbd-backlight-perms = {
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
