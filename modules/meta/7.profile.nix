{ lib, config, roles, ... }:

# ── Profile ────────────────────────────────────────────────────────────────────
# Declares options for user identity and machine-level constants.
# Every other module reads from config.profile rather than hardcoding values.
#
# roles   — injected via specialArgs from flake.nix, sourced from roles.nix
#
# role    — gates which module groups are active:
#             "personal"    full desktop + entertainment (Steam, Discord, etc.)
#             "workstation" desktop + productive/dev tools, no entertainment
#             "server"      headless, services only
#
# isRole  — helper function, pass a list of roles, returns bool
#             e.g. config.profile.isRole [ "personal" "workstation" ]
#
# has*    — machine hardware capability flags, set per nixosConfiguration
#           in flake.nix, defaults to false so missing overrides fail safe
{
  options.profile = {

    # ── Identity ───────────────────────────────────────────────────────────────
    username = lib.mkOption {
      type        = lib.types.str;
      default     = "jakub";
      description = "Primary user's login name.";
    };

    homeDirectory = lib.mkOption {
      type        = lib.types.str;
      default     = "/home/jakub";
      description = "Primary user's home directory.";
    };

    system = lib.mkOption {
      type        = lib.types.str;
      default     = "x86_64-linux";
      description = "Target system architecture.";
    };

    stateVersion = lib.mkOption {
      type        = lib.types.str;
      default     = "25.05";
      description = "NixOS and home-manager state version. Change only when explicitly migrating.";
    };

    hostname = lib.mkOption {
      type        = lib.types.str;
      default     = "nixos";
      description = "Machine hostname.";
    };

    # ── Role ───────────────────────────────────────────────────────────────────
    role = lib.mkOption {
      type        = lib.types.enum roles;
      description = ''
        Machine role — controls which module groups are active:
          personal    — full desktop + entertainment (Steam, Discord, gaming)
          workstation — desktop + productive/dev tools, no entertainment
          server      — headless, services only, no desktop stack
      '';
    };

    isRole = lib.mkOption {
      type        = lib.types.functionTo lib.types.bool;
      readOnly    = true;
      description = "Returns true if the current role matches any role in the given list.";
    };

    # ── Hardware capabilities ──────────────────────────────────────────────────
    # Set per nixosConfiguration in flake.nix.
    # Defaults to false so missing overrides fail safe.
    lanInterface = lib.mkOption {
      type        = lib.types.str;
      description = "LAN-facing network interface name.";
    };

    hasBattery = lib.mkOption {
      type        = lib.types.bool;
      default     = false;
      description = "Enables TLP and battery widget in Waybar.";
    };

    hasBacklight = lib.mkOption {
      type        = lib.types.bool;
      default     = false;
      description = "Enables keyboard backlight service and kbm script.";
    };

    hasBluetooth = lib.mkOption {
      type        = lib.types.bool;
      default     = false;
      description = "Enables blueman and Bluetooth widget in Waybar.";
    };

    # ── Display ────────────────────────────────────────────────────────────────
    primaryMonitor = lib.mkOption {
      type        = lib.types.str;
      default     = "eDP-1";
      description = "Primary monitor identifier used in compositor and Hyprland configs.";
    };

    secondaryMonitor = lib.mkOption {
      type        = lib.types.str;
      default     = "HDMI-A-1";
      description = "Secondary monitor identifier.";
    };
  };

  # roles' with a tick to avoid shadowing the `roles` specialArg
  config.profile.isRole = roles': builtins.elem config.profile.role roles';
}