# Configurations
# This dotfile defines a set of roles (roles are explained in flake.nix) used throughout the system.
#
# Each configuration is identified by its hostname (the attrset key),
# which is used as the single source of truth for bitmask and hardware identity.
#
# Bitmask values correspond to the role prefix system described in flake.nix:
#   server      = 1
#   workstation = 2
#   desktop     = 4
#
# Currently DMI is used to identify hardware.
# You can find yours by running:
#   cat /sys/devices/virtual/dmi/id/product_name
#
# To add a new machine,
# add an entry here and a corresponding nixosConfiguration in flake.nix.

{
  configurations = {
    server = {
      dmi          = "20XLS0KB02";
      bitmaskvalue = 1;
      lanInterface = "enp5s0";
      hasBattery   = true;
      hasBacklight = true;
      hasBluetooth = true;
    };
    workstation = {
      dmi          = "20XLS0KB02";
      bitmaskvalue = 2;
      lanInterface = "enp5s0";
      hasBattery   = true;
      hasBacklight = true;
      hasBluetooth = true;
    };
    desktop = {
      dmi          = "Z77X-UD3H";
      bitmaskvalue = 4;
      lanInterface = "enp6s0";
      hasBattery   = false;
      hasBacklight = false;
      hasBluetooth = true;
    };
  };
}