{ pkgs, config, ... }:

# ── Android development ────────────────────────────────────────────────────────
# Reads: config.profile.username
let
  user = config.profile.username;
in
{
  environment.systemPackages = with pkgs; [
    android-studio
    android-tools   # adb, fastboot, etc.
    jdk
    gradle
  ];

  # ANDROID_HOME and ANDROID_SDK_ROOT are expected by most Android tooling.
  # The SDK itself is managed outside Nix (Android Studio installs it).
  home-manager.users.${user}.home.sessionVariables = {
    ANDROID_HOME               = "/home/${user}/Android/Sdk";
    ANDROID_SDK_ROOT           = "/home/${user}/Android/Sdk";
    CAPACITOR_ANDROID_STUDIO_PATH = "${pkgs.android-studio}/bin/android-studio";
  };
}
