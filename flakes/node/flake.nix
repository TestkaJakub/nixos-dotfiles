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
          packages = with pkgs; [ nodejs_22 vscodium ];

          # Automatically open VSCode/VSCodium in current dir
          shellHook = ''
            echo "🚀 Starting Node.js dev environment..."
            echo "📂 Opening ${PWD} in VSCode"
            codium "${PWD}" >/dev/null 2>&1 &
          '';
        };
      });
}
