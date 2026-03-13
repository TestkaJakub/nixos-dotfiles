{ pkgs, config, ... }:

# ── Nemo — file manager ────────────────────────────────────────────────────────
# Reads: config.theme.palette
#        config.profile.username
let
  user = config.profile.username;
  t    = config.theme;

  bg     = t.palette.secondary;
  fg     = t.functions.textcolor t.palette.secondary;
  accent = t.palette.primary;
in
{
  environment.systemPackages = with pkgs; [
    nemo
    nemo-fileroller  # archive support (right-click extract/compress)
  ];

  # Set Nemo as the default directory handler
  services.gvfs.enable = true;

  home-manager.users.${user} = {
    # GTK theme — Adwaita-dark base with palette accent colors
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

    # Tell Qt apps to follow GTK theme
    qt = {
      enable         = true;
      platformTheme  = { name = "gtk"; };
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    dconf.settings."org/nemo/preferences" = {
      default-folder-viewer    = "list-view";
      show-hidden-files        = false;
      show-advanced-permissions = true;
    };
  };
}
