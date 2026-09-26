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

  # We use a standalone age key, not SSH host keys (the desktop has no sshd).
  # Setting these explicitly also skips sops-nix's default, which references
  # services.openssh.generateHostKeys — an option newer than nixos-25.11.
  sops.age.sshKeyPaths   = [ ];
  sops.gnupg.sshKeyPaths = [ ];

  environment.systemPackages = with pkgs; [ sops age ];
}