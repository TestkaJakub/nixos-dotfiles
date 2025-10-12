{
  description = "Android Emulator evironment works with fvm + flutter, included options for better compatibility, make sure to edit build.gradle.kts for cmake and other version conflicts !";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          android_sdk.accept_license = true;
        };
        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        androidComposition = androidEnv.composeAndroidPackages {
          cmdLineToolsVersion = "8.0";
          platformToolsVersion = "34.0.5";
          buildToolsVersions = [
            "34.0.0"
            "35.0.0"
          ];
          platformVersions = [
            "34"
            "36"
          ];
          abiVersions = [ "x86_64" ];
          includeNDK = true;
          ndkVersions = [ "27.0.12077973" ];
          includeCmake = true;
          includeSystemImages = true;
          systemImageTypes = [
            "google_apis"
            "google_apis_playstore"
          ];
          includeEmulator = true;
          useGoogleAPIs = true;
          extraLicenses = [
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "android-sdk-license"
            "android-sdk-preview-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"
          ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell =
          with pkgs;
          mkShell {
            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            JAVA_HOME = jdk17.home;
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
            QT_QPA_PLATFORM = "wayland;xcb";
            buildInputs = [
              androidSdk
              qemu_kvm
              gradle
              jdk17
              cmake
            ];
            LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [
              vulkan-loader
              libGL
            ]}";
          };
      }
    );
}
