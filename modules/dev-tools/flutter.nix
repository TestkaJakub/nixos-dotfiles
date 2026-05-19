{ pkgs, lib, config, ... }:

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

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ "36.0.0" "35.0.0" "34.0.0" ];
    platformVersions   = [ "36" "35" "34" ];
    abiVersions        = [ "armeabi-v7a" "arm64-v8a" ];
    includeEmulator    = false;
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

  home-manager.users.${user} = { lib, ... }: {
    home.sessionVariables = {
      ANDROID_HOME      = lib.mkForce "${androidSdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT  = lib.mkForce "${androidSdk}/libexec/android-sdk";
      ANDROID_USER_HOME = "$HOME/.android";
      JAVA_HOME         = "${pkgs.jdk17}";
    };

    # Flutter sprawdza licencje w $ANDROID_HOME/licenses/ ale nix store
    # jest read-only. Tworzymy pliki licencji w ~/.android/licenses/
    # i ustawiamy ANDROID_HOME na ten katalog jako nadrzędny przez symlink
    # w writable lokalizacji.
    #
    # Hasze licencji pochodzą z oficjalnego Android SDK.
    home.activation.androidLicenses =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.android/licenses"

        printf '8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee' \
          > "$HOME/.android/licenses/android-sdk-license"

        printf '84831b9409646a918e30573bab4c9c91346d8abd' \
          > "$HOME/.android/licenses/android-sdk-preview-license"

        printf '33b6937684c63422b0aeef7965571e9cb57b28f7\nd975f751698a77b662f1254ddbeed3901e976f5a' \
          > "$HOME/.android/licenses/android-googletv-license"

        printf 'e9acab5b5fbb560a72cfaecce8946896ff6aab9d' \
          > "$HOME/.android/licenses/mips-android-sysimage-license"
      '';
  };
}
