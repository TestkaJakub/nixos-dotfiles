{ inputs, config, ... }:

# ── YeetPatch (Voices of the Void patcher) ─────────────────────────────────────
# Module from yeetpatch-nix. Values here become defaults of the `yeetpatch`
# command; any can still be overridden per run (INSTALL_DIR=… yeetpatch install).
let
  user  = config.profile.username;
  games = "/home/${user}/data/Games";   # ← where VotV lives
in
{
  imports = [ inputs.yeetpatch.nixosModules.default ];

  programs.yeetpatch = {
    enable     = true;
    installDir = "${games}/VotV";
    exePath    = "${games}/VotV/VotV.exe";
    cacheDir   = "/home/${user}/.cache/yeetpatch";
    # saveGameDir = "…";   # back up saves before patching
    # noticeUrl   = "";    # silence the startup notice

    launcher = {
      enable          = true;                              # "Update VotV" in rofi / fuzzel
      terminalCommand = config.meta.defaults.terminalRun;  # wezterm start --
    };
  };
}