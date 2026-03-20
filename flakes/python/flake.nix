{
  description = "Python development environment";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        python = pkgs.python313;

        pythonEnv = python.withPackages (ps: with ps; [
          # ── Science / data ──────────────────────────────────────────────
          numpy
          pandas
          matplotlib
          scipy

          # ── Web / networking ────────────────────────────────────────────
          requests
          httpx

          # ── Dev tooling ─────────────────────────────────────────────────
          ipython
          black
          isort
          mypy
          pytest
        ]);
      in {
        devShells.default = pkgs.mkShell {
          name     = "python-dev-env";
          packages = [ pythonEnv pkgs.ruff pkgs.vscodium ];

          shellHook = ''
            export PS1="(python-env) $PS1"

            # Regenerate .vscode/settings.json on every `nix develop` so the
            # nix store paths stay correct after flake input updates.
            mkdir -p "$PWD/.vscode"
            cat > "$PWD/.vscode/settings.json" <<EOF
{
  "python.defaultInterpreterPath": "$(which python)",
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.ruff": "explicit",
      "source.organizeImports.ruff": "explicit"
    }
  },
  "mypy-type-checker.path": ["$(which mypy)"],
  "ruff.path": ["$(which ruff)"]
}
EOF

            codium "$PWD" &
          '';
        };
      });
}
