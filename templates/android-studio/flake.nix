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
          "python-2.7.18.8" # Or whatever the exact version string is from the error
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
	android-tools
	gradle_7
	glibc
        git
	zlib
	ncurses5
        gitRepo
        gnupg
        python2
        curl
        procps
        openssl
        gnumake
        nettools
      # For nixos < 19.03, use `androidenv.platformTools`
        androidenv.androidPkgs_9_0.platform-tools
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
        export ANDROID_JAVA_HOME=${pkgs.jdk.home}sdkmanager install avd
        export LD_LIBRARY_PATH=/usr/lib:/usr/lib32
      '';
    };
  };
}
