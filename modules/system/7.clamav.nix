{ config, ... }:

# ── ClamAV — antivirus ─────────────────────────────────────────────────────────
# On-access daemon + daily signature updates + weekly home scan.
#
# Manual scan:
#   clamscan --recursive --infected ~/Downloads
#   clamscan archive.rar
#
# Check signature age:
#   systemctl status clamav-freshclam.service
#
# Placed in system/ because it is a system-wide security concern, not
# tied to any specific user workflow.
{
  services.clamav = {

    # ── Signature updater ────────────────────────────────────────────────────
    # freshclam pulls new definitions automatically.
    # interval: how often to check for updates (default "hourly" is fine).
    updater = {
      enable   = true;
      interval = "hourly";
    };

    # ── Background daemon ────────────────────────────────────────────────────
    # clamd runs persistently so that clamscan --fdpass is fast (no cold start).
    # ExtraConfig sets sensible limits — adjust MaxFileSize / MaxScanSize if
    # you regularly deal with very large archives.
    daemon = {
      enable = true;
      settings = {
        # Do not follow symlinks into /nix/store (read-only, no threat there)
        FollowDirectorySymlinks = false;
        FollowFileSymlinks      = false;

        # Limits — bump if scanning large ISOs / game archives
        MaxFileSize   = "500M";
        MaxScanSize   = "500M";
        MaxRecursion  = 16;
        MaxFiles      = 10000;

        # Log infected files only (reduces noise)
        LogClean = false;
      };
    };

    # ── Scheduled scanner ────────────────────────────────────────────────────
    # Runs a full scan of the home directory once a week.
    # Results land in the system journal: journalctl -u clamav-scanner
    scanner = {
      enable         = true;
      interval       = "weekly";
      scanDirectories = [
        "/home/${config.profile.username}"
        "/tmp"
        "/var/tmp"
      ];
    };
  };
}
