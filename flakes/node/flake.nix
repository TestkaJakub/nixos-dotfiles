{
  description = "Node.js + VSCode development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # wrapper that replaces the absent SDK adb
        adbWrapper = pkgs.writeShellScriptBin "adb" ''
          exec ${pkgs.android-tools}/bin/adb "$@"
        '';
      in {
        devShells.default = pkgs.mkShell {
          name = "node-dev-env";
          packages = with pkgs; [
            nodejs_22
            vscodium
            android-tools
            adbWrapper      # include the wrapper in PATH
          ];

          shellHook = ''
            export PS1="(node-env) $PS1"
            export ANDROID_HOME=$HOME/Android/Sdk
            export ANDROID_SDK_ROOT=$HOME/Android/Sdk
            export PATH=${pkgs.android-tools}/bin:${pkgs.android-tools}/libexec:$PATH

            # also mirror the path inside SDK for Expo hardcoding
            mkdir -p $HOME/Android/Sdk/platform-tools
            ln -sf ${pkgs.android-tools}/bin/adb $HOME/Android/Sdk/platform-tools/adb

            codium "$PWD" &
          '';
        };
      });
}
