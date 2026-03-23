{
  description = "Python venv development environment";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name     = "python-venv-env";
          packages = with pkgs; [
            python313
            uv
            ruff
            vscodium
            stdenv.cc
            zlib
            libffi
            openssl
          ];

          shellHook = ''
            export PS1="(python-venv-env) $PS1"

            PROJECT_DIR=$(pwd)

            # Create the venv in the project directory
            if [ ! -d "$PROJECT_DIR/.venv" ]; then
              echo "Creating .venv in $PROJECT_DIR..."
              python -m venv "$PROJECT_DIR/.venv"
            fi

            source "$PROJECT_DIR/.venv/bin/activate"

            if [ -f "$PROJECT_DIR/requirements.txt" ]; then
              echo "Installing requirements..."
              uv pip install -r "$PROJECT_DIR/requirements.txt"
            fi

            # Write VSCodium settings pointing at the venv python
            mkdir -p "$PROJECT_DIR/.vscode"
            cat > "$PROJECT_DIR/.vscode/settings.json" <<EOF
{
  "python.defaultInterpreterPath": "$PROJECT_DIR/.venv/bin/python",
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.ruff": "explicit",
      "source.organizeImports.ruff": "explicit"
    }
  },
  "ruff.path": ["$(which ruff)"]
}
EOF

            echo "Python: $(which python) — $(python --version)"
            codium "$PROJECT_DIR" &
          '';
        };
      });
}
