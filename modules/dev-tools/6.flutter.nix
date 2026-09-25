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

  # ── flutter-init: naprawia nowy projekt po flutter create ────────────────────
  # NixOS problem: AGP (Android Gradle Plugin) hardkoduje cmake;3.22.1 i próbuje
  # go pobrać przez sdkmanager mimo że system ma nowszy cmake w PATH.
  # Rozwiązanie:
  #   1. Zastąp flutter.ndkVersion konkretną wersją z ~/.android/sdk/ndk/
  #   2. Dopisz cmake.version = "X.Y.Z+" do build.gradle.kts żeby AGP użył
  #      systemowego cmake zamiast pobierać 3.22.1
  #   3. Dopisz cmake.dir do local.properties
  #
  # Użycie:
  #   flutter create my_app
  #   cd my_app
  #   flutter-init
  #   flutter run
  flutterInit = pkgs.writeShellScriptBin "flutter-init" ''
    set -e

    # ── Sprawdź czy jesteśmy w katalogu Flutter projektu ──────────────────────
    if [ ! -f "pubspec.yaml" ] || [ ! -d "android" ]; then
      echo "flutter-init: uruchom w katalogu projektu Flutter (po flutter create)"
      exit 1
    fi

    gradle_kts="android/app/build.gradle.kts"
    local_props="android/local.properties"

    if [ ! -f "$gradle_kts" ]; then
      echo "flutter-init: nie znaleziono $gradle_kts"
      exit 1
    fi

    # ── 1. Znajdź zainstalowaną wersję NDK ────────────────────────────────────
    ndk_dir="$HOME/.android/sdk/ndk"
    if [ ! -d "$ndk_dir" ]; then
      echo "flutter-init: brak katalogu NDK w $ndk_dir"
      exit 1
    fi

    ndk_version=$(ls "$ndk_dir" | sort -V | tail -1)
    if [ -z "$ndk_version" ]; then
      echo "flutter-init: brak zainstalowanego NDK"
      exit 1
    fi
    echo "  NDK: $ndk_version"

    # ── 2. Znajdź wersję cmake z nix store ────────────────────────────────────
    cmake_bin=$(command -v cmake 2>/dev/null || true)
    if [ -z "$cmake_bin" ]; then
      echo "flutter-init: cmake nie znaleziony w PATH"
      exit 1
    fi
    cmake_version=$("$cmake_bin" --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "  CMake: $cmake_version"

    # ── 3. Zastąp flutter.ndkVersion konkretną wersją ─────────────────────────
    if grep -q "flutter\.ndkVersion" "$gradle_kts"; then
      sed -i "s/ndkVersion = flutter\.ndkVersion/ndkVersion = \"$ndk_version\"/" "$gradle_kts"
      echo "  ndkVersion → $ndk_version"
    else
      echo "  ndkVersion już ustawiony, pomijam"
    fi

    # ── 4. Dopisz cmake.version jeśli jeszcze nie ma ──────────────────────────
    if ! grep -q "externalNativeBuild" "$gradle_kts"; then
      printf '\n// flutter-init: użyj systemowego cmake zamiast pobierać przez sdkmanager\nandroid.externalNativeBuild.cmake.version = "%s+"\n' "$cmake_version" >> "$gradle_kts"
      echo "  cmake.version → $cmake_version+"
    else
      echo "  cmake.version już ustawiony, pomijam"
    fi

    # ── 5. Dopisz cmake.dir do local.properties jeśli jeszcze nie ma ──────────
    cmake_dir="$HOME/.android/sdk/ndk/$ndk_version/build/cmake"
    if ! grep -q "cmake.dir" "$local_props" 2>/dev/null; then
      echo "cmake.dir=$cmake_dir" >> "$local_props"
      echo "  cmake.dir → $cmake_dir"
    else
      echo "  cmake.dir już ustawiony, pomijam"
    fi

    echo ""
    echo "Gotowe — możesz teraz uruchomić: flutter run"
  '';
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
    flutterInit
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
