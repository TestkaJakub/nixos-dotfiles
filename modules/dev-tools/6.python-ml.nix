{ pkgs, ... }:

# ── Python + ML / data-science environment ─────────────────────────────────────
# A declarative Python interpreter bundled with the core scientific + ML stack,
# plus Jupyter Lab. Built with python3.withPackages, so every library is pinned
# by the flake and reproducible — no `pip install` into a global env (which
# fights NixOS anyway). The bundled `python`/`ipython`/`jupyter` all see every
# library listed below out of the box.
#
# ── Usage ──────────────────────────────────────────────────────────────────────
#   jupyter lab            # notebook UI in your browser (http://localhost:8888)
#   ipython                # rich REPL
#   python                 # plain REPL / run scripts
#
# ── Adding a library that IS in nixpkgs ────────────────────────────────────────
#   Add it to the `ps: with ps; [ ... ]` list below and run `nrs`.
#   Browse names at https://search.nixos.org (filter: Packages, prefix python3Packages).
#
# ── Adding a library that is NOT in nixpkgs, or a specific pinned version ───────
#   Very common when following ML courses that say "pip install X". Use a
#   throwaway virtualenv — nix-ld (already enabled in system/nix.nix) lets pip's
#   precompiled wheels run unpatched:
#
#     uv venv .venv && source .venv/bin/activate && uv pip install <pkg>
#       (uv is installed below — it's a fast drop-in for pip/venv)
#   or plain:
#     python -m venv .venv --system-site-packages && source .venv/bin/activate
#     pip install <pkg>
#
#   Pair it with direnv (you already have it) via an `.envrc` containing
#   `layout python` or `source .venv/bin/activate` for auto-activation per project.

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    # ── Notebook / interactive ──────────────────────────────────────────────
    jupyterlab
    ipython
    ipykernel
    ipywidgets

    # ── Core numerics / data ────────────────────────────────────────────────
    numpy
    pandas
    scipy

    # ── Plotting / visualisation ────────────────────────────────────────────
    matplotlib
    seaborn
    plotly

    # ── Classical ML ────────────────────────────────────────────────────────
    scikit-learn
    statsmodels
    # xgboost              # gradient boosting — uncomment when you want it

    # ── Handy extras ────────────────────────────────────────────────────────
    tqdm                   # progress bars
    pillow                 # image loading
    requests               # fetching datasets
    sympy                  # symbolic maths

    # ── Deep learning (CPU) ─────────────────────────────────────────────────
    # torch & friends are large and occasionally rebuild — uncomment once you
    # reach neural nets. For GPU acceleration on your RX 9070 XT you'd want a
    # ROCm build, which is far easier via a venv/uv with the official ROCm
    # wheels than through nixpkgs.
    # torch
    # torchvision
  ]);
in
{
  environment.systemPackages = [
    pythonEnv
    pkgs.uv                # fast pip/venv manager for the escape-hatch workflow
  ];
}