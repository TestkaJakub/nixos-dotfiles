{ config, ... }:

# ── VSCode/VSCodium remote server ──────────────────────────────────────────────
# Enables Open Remote SSH support from VSCodium on the workstation.
let
  user = config.profile.username;
in
{
  services.vscode-server = {
    enable = true;
    nodejsPackage = null; # uses the bundled node from the extension
  };

  home-manager.users.${user}.services.vscode-server.enable = true;
}