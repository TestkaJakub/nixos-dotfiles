{ pkgs, ... }:

# ── Vivaldi ────────────────────────────────────────────────────────────────────
# Brave pulls GTK4 into the session which conflicts with Vivaldi's hardcoded
# GTK3 wrapper. Shell wrapper strips gtk+3 from LD_LIBRARY_PATH before launch.
let
  vivaldi-wrapped = pkgs.writeShellScriptBin "vivaldi" ''
    clean_ldpath=$(echo "''${LD_LIBRARY_PATH:-}" \
      | tr ':' '\n' \
      | grep -v 'gtk+3' \
      | tr '\n' ':' \
      | sed 's/:$//')

    clean_xdg=$(echo "''${XDG_DATA_DIRS:-}" \
      | tr ':' '\n' \
      | grep -v 'gtk+3' \
      | tr '\n' ':' \
      | sed 's/:$//')

    export LD_LIBRARY_PATH="$clean_ldpath"
    export XDG_DATA_DIRS="$clean_xdg"

    exec /nix/store/5fpqix5g6h3y0p9aga54igw2b1sjacg1-vivaldi-7.9.3970.55/bin/.vivaldi-wrapped \
      --ozone-platform=x11 \
      --gtk-version=4 \
      "$@"
  '';
in
{
  environment.systemPackages = [
    vivaldi-wrapped   # replaces pkgs.vivaldi entirely — provides the vivaldi binary
  ];
}