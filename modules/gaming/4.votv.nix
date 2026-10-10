{ pkgs, inputs, config, ... }:

# ── Voices of the Void ─────────────────────────────────────────────────────────
# YeetPatch: module from yeetpatch-nix. Values here become defaults of the
# `yeetpatch` command; any can still be overridden per run.
# Gale: Thunderstore mod manager (VotV mods go through Shimloader / UE4SS).
let
  user  = config.profile.username;
  games = "/home/${user}/data/Games";   # ← where VotV lives
in
{
  imports = [ inputs.yeetpatch.nixosModules.default ];

  programs.yeetpatch = {
    enable     = true;
    installDir = "${games}/VotV";
    exePath    = "${games}/VotV/WindowsNoEditor/VotV.exe";
    cacheDir   = "/home/${user}/.cache/yeetpatch";

    launcher = {
      enable          = true;
      terminalCommand = config.meta.defaults.terminalRun;
    };
  };

  environment.systemPackages = [ pkgs.gale ];
}