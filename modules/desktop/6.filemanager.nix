{ pkgs, config, ... }:

# ── Nemo — file manager ────────────────────────────────────────────────────────
# Note: services.gvfs.enable is set in system/peripherals.nix — not here.
# GTK/Qt theme, fonts and cursor are managed by Stylix (meta/7.stylix.nix).
let
  user = config.profile.username;
in
{
  environment.systemPackages = with pkgs; [
    nemo
    nemo-fileroller
    nemo-preview
    file-roller
  ];

  home-manager.users.${user} = { lib, ... }: {
    xresources.properties."Xft.dpi" = 131;

    dconf.settings."org/nemo/preferences" = {
      default-folder-viewer     = "list-view";
      show-hidden-files         = false;
      show-advanced-permissions = true;
    };

    # Fix thumbnail cache permissions — Nemo complains if these are wrong
    home.activation.fixThumbnailCache =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.cache/thumbnails/"{normal,large,x-large,xx-large,fail}
        chmod 700 "$HOME/.cache/thumbnails"
        find "$HOME/.cache/thumbnails" -type d -exec chmod 700 {} \;
        find "$HOME/.cache/thumbnails" -type f -exec chmod 600 {} \;
      '';
  };
}