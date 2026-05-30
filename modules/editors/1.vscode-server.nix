{ ... }:

# ── VSCode/VSCodium remote server ──────────────────────────────────────────────
# Enables Open Remote SSH support from VSCodium on the workstation.
{
  services.vscode-server = {
    enable = true;
    installPath = "$HOME/.vscodium-server";
  };
}