{ pkgs, config, ... }:

# ── Nemo — file manager ────────────────────────────────────────────────────────
# Note: services.gvfs.enable is set in system/peripherals.nix — not here.
let
  user   = config.profile.username;
  t      = config.theme;
  bg     = t.palette.secondary;
  accent = t.palette.primary;
in
{
  environment.systemPackages = with pkgs; [
    nemo
    nemo-fileroller
    nemo-preview
    file-roller
  ];

  home-manager.users.${user} = { lib, ... }: {
    xresources.properties = {
      "Xft.dpi"      = 131;
      "Xcursor.size" = 32;
    };

    home.pointerCursor = {
      package    = pkgs.adwaita-icon-theme;
      name       = "Adwaita";
      size       = 32;
      x11.enable = true;
      gtk.enable = true;
    };

    gtk = {
      enable = true;
      font = {
        name    = "Noto Sans";
        size    = 14;
        package = pkgs.noto-fonts;
      };
      theme = {
        name    = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
    };

    qt = {
      enable        = true;
      platformTheme = { name = "gtk"; };
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

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
