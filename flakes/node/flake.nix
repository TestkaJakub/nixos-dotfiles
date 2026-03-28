{
  description = "Node.js + VSCode development environment";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Shim: Expo / React Native hardcode SDK path and expect adb there.
        adbWrapper = pkgs.writeShellScriptBin "adb" ''
          exec ${pkgs.android-tools}/bin/adb "$@"
        '';
      in {
        devShells.default = pkgs.mkShell {
          name     = "node-dev-env";
          packages = with pkgs; [ nodejs_22 vscodium android-tools adbWrapper ];

          shellHook = ''
            export PS1="(node-env) $PS1"
            export ANDROID_HOME=$HOME/Android/Sdk
            export ANDROID_SDK_ROOT=$HOME/Android/Sdk
            export PATH=${pkgs.android-tools}/bin:${pkgs.android-tools}/libexec:$PATH

            mkdir -p $HOME/Android/Sdk/platform-tools
            ln -sf ${pkgs.android-tools}/bin/adb $HOME/Android/Sdk/platform-tools/adb

            # Pin VSCodium's integrated terminal to bash so the nix shell
            # environment (PATH, NODE_PATH, etc.) is inherited. Without this,
            # VSCodium opens fish which doesn't inherit the nix dev shell env.
            mkdir -p "$PWD/.vscode"
            cat > "$PWD/.vscode/settings.json" <<EOF
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "${pkgs.bash}/bin/bash"
    }
  }
}
EOF

            codium "$PWD" &
          '';
        };
      });
}
