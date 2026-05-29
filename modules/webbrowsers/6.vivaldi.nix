{ pkgs, ... }:

# ── Vivaldi ────────────────────────────────────────────────────────────────────
# Brave pulls GTK4 into the session, so Vivaldi must also use GTK4.
# The nixpkgs wrapper hardcodes gtk+3 in LD_LIBRARY_PATH and XDG_DATA_DIRS,
# so we swap it out at the package level via overrideAttrs.
let
  vivaldi-gtk4 = pkgs.vivaldi.overrideAttrs (old: {
    buildInputs = map (p:
      if p == pkgs.gtk3 then pkgs.gtk4 else p
    ) (old.buildInputs or []);

    postFixup = (old.postFixup or "") + ''
      # Replace gtk+3 with gtk4 in the wrapper's LD_LIBRARY_PATH
      sed -i "s|${pkgs.gtk3}/lib|${pkgs.gtk4}/lib|g" $out/bin/vivaldi
      sed -i "s|${pkgs.gtk3}/share/gsettings-schemas[^'\"]*|${pkgs.gtk4}/share/gsettings-schemas/gtk-4.0|g" $out/bin/vivaldi
    '';
  });
in
{
  environment.systemPackages = [
    (vivaldi-gtk4.override {
      commandLineArgs = [
        "--ozone-platform=x11"
        "--gtk-version=4"
      ];
    })
  ];
}