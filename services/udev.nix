{ pkgs, ... }:
{
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="tpacpi::kbd_backlight", \
      RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/class/leds/tpacpi::kbd_backlight/brightness"
  '';
}
