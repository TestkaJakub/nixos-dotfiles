{
  description = "JS/TS development environment with VSCode and Node.js";

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
          name = "node-dev-shell";
          packages = with pkgs; [
            nodejs_22  # Node.js + npm
            vscodium   # or vscode
          ];

          shellHook = ''
            echo "🚀 Node.js development environment ready"
            node --version
            npm --version
          '';
        };
      });
}
