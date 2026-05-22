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
    gtk = {
      enable = true;
      theme = {
        name    = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      gtk3.extraCss = ''
        * {
          --accent-bg-color: ${accent};
          --accent-color: ${accent};
          --accent-fg-color: ${bg};
        }
        .view:selected,
        row:selected,
        .nemo-window .nemo-places-sidebar row:selected {
          background-color: ${accent};
          color: ${bg};
        }
      '';
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
