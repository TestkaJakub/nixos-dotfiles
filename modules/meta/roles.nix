# ── Roles and configurations ────────────────────────────────────────────────
# Single source of truth for roles, hostnames and hardware identifiers.
# Imported by flake.nix and passed to modules via specialArgs as:
#   { roles, configurations }
#
# dmi — DMI product name, used in hardware/assertions.nix to prevent
#        building the wrong configuration on the wrong physical machine.
#        Find yours with: cat /sys/devices/virtual/dmi/id/product_name
#
# To add a new machine: add an entry here and a corresponding
# nixosConfiguration in flake.nix.
{
  roles = [ "server" "workstation" "personal" ];

  configurations = {
    nixos = {
      role     = "workstation";
      hostname = "nixos";
      dmi      = "20XLS0KB02";
    };
    nixos-server = {
      role     = "server";
      hostname = "nixos-server";
      dmi      = "20XLS0KB02";
    };
    desktop = {
      role     = "personal";
      hostname = "desktop";
      dmi      = "Z77X-UD3H";
    };
  };
}