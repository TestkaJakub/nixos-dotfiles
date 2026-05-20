{ pkgs, lib, config, ... }:

# ── Flutter — standalone dev environment ───────────────────────────────────────
# Wszystkie zależności (SDK, JDK, narzędzia) są zdefiniowane i zarządzane
# wyłącznie w tym module. Nie wymaga android.nix ani żadnego innego modułu.
#
# Problem z nix store (read-only):
#   Flutter wymaga katalogu $ANDROID_HOME/licenses/ z możliwością zapisu.
#   Rozwiązanie: ANDROID_HOME → ~/.android/sdk — katalog z symlinkami
#   do komponentów SDK w nix store + zapisywalny folder licenses/.
#
# Activation script przy każdym rebuildie:
#   1. Tworzy ~/.android/sdk/ z symlinkami do komponentów SDK
#   2. Tworzy ~/.android/sdk/licenses/ z plikami licencji (jeśli nie istnieje)
#
# Użycie:
#   flutter create my_app
#   flutter run
#   flutter build apk --release
let
  user = config.profile.username;

  # ── Android SDK złożony w tym module ────────────────────────────────────────
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

  # ── JDK zdefiniowany lokalnie ────────────────────────────────────────────────
  jdk = pkgs.jdk17;
in
{
  # ── Pakiety systemowe ────────────────────────────────────────────────────────
  environment.systemPackages = [
    pkgs.flutter
    pkgs.dart
    jdk
    androidSdk
    pkgs.android-tools   # adb, fastboot
    pkgs.gradle
  ];

  # ── Konfiguracja użytkownika ─────────────────────────────────────────────────
  home-manager.users.${user} = { lib, ... }: {

    # ANDROID_HOME wskazuje na writable katalog z symlinkami do nix store
    home.sessionVariables = {
      ANDROID_HOME     = "$HOME/.android/sdk";
      ANDROID_SDK_ROOT = "$HOME/.android/sdk";
      JAVA_HOME        = "${jdk}";
    };

    # Activation: buduje ~/.android/sdk/ przy każdym rebuildie
    #
    # Symlinki są odświeżane (ln -sfT) żeby zawsze wskazywały na aktualny
    # store path (hash zmienia się przy zmianie wersji SDK).
    # Folder licenses/ tworzony tylko raz — żeby nie nadpisywać haszy
    # zaakceptowanych przez sdkmanager.
    home.activation.flutterAndroidSdk =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        sdk="${nixSdk}"
        target="$HOME/.android/sdk"
        mkdir -p "$target"

        # Symlinki do wszystkich komponentów SDK poza licenses/
        for item in "$sdk"/*; do
          name=$(basename "$item")
          if [ "$name" != "licenses" ]; then
            ln -sfT "$item" "$target/$name"
          fi
        done

        # Licencje — tworzone tylko jeśli folder nie istnieje
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
