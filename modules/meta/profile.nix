{ lib, ... }:

# ── Profile ────────────────────────────────────────────────────────────────────
# Declares options for user identity and system-level constants.
# Every other module reads from config.profile rather than hardcoding values
# or receiving them via specialArgs.
{
  options.profile = {
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
  };
}
