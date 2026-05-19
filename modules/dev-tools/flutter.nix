{ pkgs, lib, config, ... }:

# ── Flutter ────────────────────────────────────────────────────────────────────
# Flutter SDK + Android toolchain for mobile development.
# Android SDK jest zarządzany przez Nix ale nix store jest read-only,
# więc Flutter nie może zapisać licencji w $ANDROID_HOME/licenses/.
#
# Rozwiązanie: ANDROID_HOME wskazuje na ~/.android/sdk — katalog z symlinkami
# do prawdziwego SDK w nix store, plus zapisywalny folder licenses/.
# Activation script tworzy tę strukturę przy każdym rebuildie.
#
# Usage:
#   flutter create my_app
#   flutter run
#   flutter build apk --release
#
# F-Droid: buduj bez Google Play Services / Firebase.
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
  nixSdk     = "${androidSdk}/libexec/android-sdk";
in
{
  environment.systemPackages = with pkgs; [
    flutter
    dart
    jdk17
    androidSdk
    android-tools
    gradle
  ];

  home-manager.users.${user} = { lib, ... }: {
    # ANDROID_HOME wskazuje na ~/.android/sdk — writable katalog z symlinkami
    home.sessionVariables = {
      ANDROID_HOME     = lib.mkForce "$HOME/.android/sdk";
      ANDROID_SDK_ROOT = lib.mkForce "$HOME/.android/sdk";
      JAVA_HOME        = "${pkgs.jdk17}";
    };

    # Przy każdym rebuildie:
    #   1. Tworzy ~/.android/sdk/ z symlinkami do komponentów w nix store
    #   2. Tworzy ~/.android/sdk/licenses/ z plikami licencji (writable)
    #
    # Symlinki są odświeżane przy każdym rebuildie żeby zawsze wskazywały
    # na aktualny store path (hash zmienia się przy zmianie wersji SDK).
    home.activation.androidSdk =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        sdk="${nixSdk}"
        target="$HOME/.android/sdk"
        mkdir -p "$target"

        # Symlinki do wszystkich komponentów SDK poza licenses/
        # -sfT (no-dereference) żeby nie tworzyć symlinku wewnątrz katalogu
        for item in "$sdk"/*; do
          name=$(basename "$item")
          if [ "$name" != "licenses" ]; then
            ln -sfT "$item" "$target/$name"
          fi
        done

        # Tworzy licencje tylko jeśli folder nie istnieje —
        # żeby nie nadpisywać haszy zaakceptowanych przez sdkmanager
        if [ ! -d "$target/licenses" ]; then
          mkdir -p "$target/licenses"

          printf '8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee' \
            > "$target/licenses/android-sdk-license"

          printf '84831b9409646a918e30573bab4c9c91346d8abd' \
            > "$target/licenses/android-sdk-preview-license"

          printf '33b6937684c63422b0aeef7965571e9cb57b28f7\nd975f751698a77b662f1254ddbeed3901e976f5a' \
            > "$target/licenses/android-googletv-license"

          printf 'e9acab5b5fbb560a72cfaecce8946896ff6aab9d' \
            > "$target/licenses/mips-android-sysimage-license"
        fi
      '';
  };
}
