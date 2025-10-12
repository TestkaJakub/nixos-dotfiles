{
  description = "Template: Android development environment";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "python-2.7.18.8"
        ];
      };
    };
  in {
    templates.default = {
      path = ./.;
      description = "Android-studio development environment template";
    };
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        android-studio
        android-tools # Consider if you still need this if using androidenv
        gradle_7
        glibc
        git
        zlib
        ncurses5
        gitRepo
        gnupg
        python2 # Keep this if strictly necessary, but ideally try to remove later
        curl
        procps
        openssl
        gnumake
        nettools

        # --- MODIFICATION STARTS HERE ---
        # Replace the problematic line with the correct way to get platform-tools
        androidenv.androidSdk.platform-tools # This is the most common modern way
        # If the above doesn't work, you might need:
        # androidenv.platform-tools # Older way
        # androidenv.androidSdk.build-tools."34.0.0" # Example for build-tools

        # --- MODIFICATION ENDS HERE ---

        jdk
        schedtool
        util-linux
        m4
        gperf
        perl
        libxml2
        zip
        unzip
        bison
        flex
        lzop
        python3
      ];
      shellHook = ''
        export ALLOW_NINJA_ENV=true
        export USE_CCACHE=1
        export ANDROID_JAVA_HOME=${pkgs.jdk.home}
        # The 'sdkmanager install avd' part is problematic in shellHook
        # You usually run sdkmanager interactively or via a script.
        # Removing this from shellHook for now to get the shell to launch.
        # You'll likely want to run 'sdkmanager "platform-tools" "platforms;android-XX"' etc.
        # manually, or wrap it in a custom script.
        export LD_LIBRARY_PATH=/usr/lib:/usr/lib32
      '';
    };
  };
}
