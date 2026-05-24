{ lib, ... }:

# ── Locale ─────────────────────────────────────────────────────────────────────
# Declares localisation options. Consumed by:
#   - system/boot.nix      (console.keyMap, xkb layout)
#   - system/nix.nix       (time.timeZone)
#   - desktop/compositor.nix (xkb_layout in mango config)
#   - desktop/bar.nix      (gammastep coordinates)
{
  options.locale = {
    keyboardLayout = lib.mkOption {
      type        = lib.types.str;
      default     = "pl";
      description = "XKB keyboard layout identifier.";
    };

    consoleKeyMap = lib.mkOption {
      type        = lib.types.str;
      default     = "pl2";
      description = "Linux console keymap (loadkeys name).";
    };

    timezone = lib.mkOption {
      type        = lib.types.str;
      default     = "Europe/Warsaw";
      description = "System timezone (TZ database name).";
    };

    latitude = lib.mkOption {
      type        = lib.types.float;
      default     = 52.4;
      description = "Geographic latitude, used for gamma/night-light calculations.";
    };

    longitude = lib.mkOption {
      type        = lib.types.float;
      default     = 17.0;
      description = "Geographic longitude, used for gamma/night-light calculations.";
    };

    defaultLocale = lib.mkOption {
      type        = lib.types.str;
      default     = "en_US.UTF-8";
      description = "System default locale.";
    };

    extraLocales = lib.mkOption {
      type        = lib.types.listOf lib.types.str;
      default     = [ "pl_PL.UTF-8/UTF-8" "en_GB.UTF-8/UTF-8" ];
      description = "Additional locales to generate.";
    };
  };
}
