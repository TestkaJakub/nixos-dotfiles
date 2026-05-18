{ pkgs, config, ... }:

# ── Flutter ────────────────────────────────────────────────────────────────────
# Flutter SDK + Android toolchain for mobile development.
# Android SDK is managed by Nix — no Android Studio needed.
#
# Usage:
#   flutter create my_app
#   flutter run              # wymaga podłączonego urządzenia lub emulatora
#   flutter build apk --release
#
# F-Droid: apk musi być zbudowany bez Google Play Services / Firebase.
# Używaj wyłącznie paczek bez zamkniętych zależności.
#
# Emulator (opcjonalny): uruchom Android Studio raz żeby skonfigurować AVD,
# albo użyj fizycznego urządzenia przez adb.
let
  user = config.profile.username;

  buildToolsVersion = "34.0.0";

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ buildToolsVersion "33.0.1" ];
    platformVersions   = [ "34" "33" ];
    abiVersions        = [ "armeabi-v7a" "arm64-v8a" ];
    includeEmulator    = false;   # zmień na true jeśli chcesz emulator
    includeSources     = false;
    extraLicenses = [
      "android-sdk-license"
      "android-sdk-preview-license"
    ];
  };

  androidSdk = androidComposition.androidsdk;
in
{
  environment.systemPackages = with pkgs; [
    flutter
    dart
    jdk17
    androidSdk
    android-tools   # adb, fastboot
    gradle
  ];

  # Wymagane do flutter doctor — akceptacja licencji SDK
  nixpkgs.config.android_sdk.accept_license = true;

  home-manager.users.${user}.home.sessionVariables = {
    ANDROID_HOME     = "${androidSdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    JAVA_HOME        = "${pkgs.jdk17}";
  };

  # Flutter wymaga zapisu do ~/.flutter — katalog jest poza /nix/store
  # więc nie trzeba nic specjalnego robić. Ale gradle cache może być duży.
  # Żeby wyczyścić: rm -rf ~/.gradle/caches
}
