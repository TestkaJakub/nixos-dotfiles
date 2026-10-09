{ pkgs, inputs, ... }:

# ── YeetPatch (Voices of the Void patcher) ─────────────────────────────────────
# Packaged in its own flake (yeetpatch-nix), pulled in as the `yeetpatch` input.
# Files land in /run/current-system/sw/share/yeetpatch
{
  environment.systemPackages = [
    inputs.yeetpatch.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}