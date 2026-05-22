{ pkgs, ... }:

# ── Arduino ────────────────────────────────────────────────────────────────────
# Packages only. The ard() shell function that wraps arduino-cli lives in
# shell/bash.nix since it is a shell concern, not an Arduino concern.
{
  environment.systemPackages = with pkgs; [
    arduino-core
    arduino-cli
  ];
}
