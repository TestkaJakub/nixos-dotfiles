{ inputs, ... }:

# ── Bambu Studio ───────────────────────────────────────────────────────────────
# Official AppImage via github:TestkaJakub/bambu-studio-nix.
# Update: bump package.nix there, then nix flake update bambu-studio && nrs
{
  imports = [ inputs.bambu-studio.nixosModules.default ];

  programs.bambu-studio.enable = true;
}