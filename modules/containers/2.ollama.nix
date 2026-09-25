# modules/dev-tools/2.ollama-client.nix
{ pkgs, ... }:

# ── Ollama client → desktop GPU ───────────────────────────────────────────────
# CLI only; no local service, no local models. Talks to the desktop's ROCm
# Ollama over Tailscale (exposed by tailscale serve in containers/4.ollama-rcom.nix).
{
  environment.systemPackages               = [ pkgs.ollama ];
  environment.sessionVariables.OLLAMA_HOST = "http://desktop:11434";
}