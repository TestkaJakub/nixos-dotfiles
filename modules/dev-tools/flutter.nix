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
# Dwa katalogi licencji:
#   sdkmanager zapisuje do ~/.android/licenses/
#   Flutter szuka w   ~/.android/sdk/licenses/
#   Rozwiązanie: ~/.android/sdk/licenses → symlink do ~/.android/licenses/
#   Dzięki temu oba narzędzia korzystają z tego samego miejsca.
#
# Pierwsze użycie po rebuildie:
#   flutter doctor --android-licenses   (wciśnij y na wszystko — jednorazowo)
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
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-googlexr-license"
      "google-gdk-license"
      "mips-android-sysimage-license"
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
    pkgs.mesa-demos      # eglinfo — wymagane przez flutter doctor
  ];

  # ── Konfiguracja użytkownika ─────────────────────────────────────────────────
  home-manager.users.${user} = { lib, ... }: {

    # ANDROID_HOME wskazuje na writable katalog z symlinkami do nix store
    home.sessionVariables = {
      ANDROID_HOME       = lib.mkForce "$HOME/.android/sdk";
      ANDROID_SDK_ROOT   = lib.mkForce "$HOME/.android/sdk";
      JAVA_HOME          = "${jdk}";
      # Flutter web dev — Vivaldi jest Chromium-based, więc w pełni wspierany
      CHROME_EXECUTABLE  = "${pkgs.vivaldi}/bin/vivaldi";
    };

    # Activation: buduje ~/.android/sdk/ przy każdym rebuildie
    #
    # Symlinki do komponentów SDK są odświeżane (ln -sfT) żeby zawsze
    # wskazywały na aktualny store path (hash zmienia się przy zmianie wersji).
    #
    # Licencje: sdkmanager zapisuje do ~/.android/licenses/, Flutter szuka
    # w ~/.android/sdk/licenses/ — rozwiązanie: symlink między tymi dwoma.
    # Dzięki temu flutter doctor --android-licenses działa trwale.
    home.activation.flutterAndroidSdk =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        sdk="${nixSdk}"
        target="$HOME/.android/sdk"
        licenses="$HOME/.android/licenses"

        mkdir -p "$target"
        mkdir -p "$licenses"

        # Symlinki do wszystkich komponentów SDK poza licenses/
        for item in "$sdk"/*; do
          name=$(basename "$item")
          if [ "$name" != "licenses" ]; then
            ln -sfT "$item" "$target/$name"
          fi
        done

        # ~/.android/sdk/licenses → symlink do ~/.android/licenses/
        # sdkmanager i Flutter korzystają z tego samego katalogu
        ln -sfT "$licenses" "$target/licenses"
      '';
  };
}
