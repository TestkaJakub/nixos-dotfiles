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
      in {
        devShells.default = pkgs.mkShell {
          name = "node-dev-env";
          packages = with pkgs; [ 
	    nodejs_22
	    vscodium
	    android-tools
	  ];

          shellHook = ''
            export PS1="(node-env) $PS1"
	    export ADB=${pkgs.android-tools}/bin/adb
	    export ANDROID_HOME=$HOME/Android/Sdk
	    export ANDROID_SDK_ROOT=$HOME/Android/Sdk
            codium "$PWD" &
          '';
        };
      });
}
