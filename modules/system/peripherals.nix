{ pkgs, config, ... }:

# ── Peripherals ────────────────────────────────────────────────────────────────
{
  # Bluetooth
  services.blueman.enable = true;

  # Storage / removable media
  services.devmon.enable  = true;
  services.gvfs.enable    = true;
  services.udisks2.enable = true;

  # Graphics tablets
  hardware.opentabletdriver.enable = true;
  hardware.uinput.enable           = true;

  # Keyboard backlight — one-shot service runs at boot so kbm() works without sudo.
  systemd.services.kbd-backlight-perms = {
    description   = "Allow users group to write keyboard backlight brightness";
    wantedBy      = [ "multi-user.target" ];
    after         = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/tpacpi::kbd_backlight/brightness";
      RemainAfterExit = true;
    };
  };

  users.users.${config.profile.username}.extraGroups = [ "users" ];
}
