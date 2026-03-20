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
            codium "$PWD" &
          '';
        };
      });
}
