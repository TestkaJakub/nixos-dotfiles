{ pkgs, ... }:

# ── sops-nix — encrypted secrets in the repo ───────────────────────────────────
# Encrypted files: ./secrets/*.yaml      Access rules: ./.sops.yaml
#
#   sops secrets/common.yaml               edit (decrypts in $EDITOR, re-encrypts on save)
#   sops updatekeys secrets/*.yaml         after changing keys in .sops.yaml
#
# Keys (never in the repo):
#   machine   /var/lib/sops-nix/key.txt        decrypts at activation
#   personal  ~/.config/sops/age/keys.txt      edits secrets (backed up in Bitwarden)
#
# Secrets are declared in the module that uses them (sops.secrets.<name>)
# and appear at /run/secrets/<name> with the owner/mode set there.
{
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  environment.systemPackages = with pkgs; [ sops age ];
}