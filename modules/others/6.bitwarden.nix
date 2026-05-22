{ pkgs, ... }:

# ── Bitwarden ──────────────────────────────────────────────────────────────────
# Cloud-synced password manager.
{
  environment.systemPackages = [ pkgs.bitwarden-desktop ];
}
